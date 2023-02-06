#!/bin/bash

## Program needs folders Input_pheno_folder, Input_geno_folder the Scripts folder


main(){
	set_variables
	convert_files
	file_to_array
	run_midesp
	}


set_variables(){
	Source_Folder=/home/s412291/PROJECT/2_GBLUP
	INPUT_GENO_FOLDER=/home/s412291/PROJECT/2_GBLUP/Inputs/genos_f
	INPUT_PHENO_FOLDER=/home/s412291/PROJECT/2_GBLUP/Inputs/phenos_f
}


convert_files(){
		
	mkdir -p TEMP_TPED_FOLDER TEMP_TFAM_FOLDER

# Creating sample list file
	cd $INPUT_GENO_FOLDER
	printf "%s\n" *.csv > ../sample_list
	sed -i "s/\.csv//" ../sample_list
	cat ../sample_list
	cd ..
	cd ..
		
		
	input=$Source_Folder/Inputs/sample_list
	while IFS= read -r line
		do
			echo "$line"
			
				Rscript Scripts/ConvertCSV_v2.R \
				--genoFile $INPUT_GENO_FOLDER/${line}.csv \
				--phenoFile $INPUT_PHENO_FOLDER/${line}.csv \
				--tpedFile TEMP_TPED_FOLDER/${line}.tped \
				--tfamFile TEMP_TFAM_FOLDER/${line}.tfam &			
		done < "$input"
        wait
}

file_to_array(){	
	cd TEMP_TPED_FOLDER
	declare -ga FILELIST=( $(ls | grep '.tped$' | sed 's/.tped$//') )
    printf '%s\n' "${FILELIST[@]}"
	printf '\n'
	cd $Source_Folder
}

run_midesp(){
	#SNP interaction analysis
	# -cont		indicate that the phenotype is continuous
	# -k		number	set the value of k for MI estimation for continuous phenotypes (default = 30)
	# -keep		number	keep only the top X percentage pairs with highest MI (default = 1)
	# -apc		number	set the number of samples that should be used to estimate the average effects of the SNPs (default = 5000)
	# -list		file	name of file with list of SNP IDs to analyze instead of using the SNPs that are significant according to their MI value
		
	mkdir -p midesp_output

	for i in "${FILELIST[@]}"
		do
					  
			    varcsv=$(awk -F, 'NR==2 { print $3 }' $INPUT_PHENO_FOLDER/"$i".csv)
				
				if [[ $varcsv == 0 || $varcsv == 1 ]]; then
					printf "Analyzing "$i" .. \n"				
					head -n5 $INPUT_PHENO_FOLDER/"$i".csv 
					# awk -F "\"*,\"*" '{print $3}' $Source_Folder/phenos/"$i".csv 
					echo "$i has discrete phenotype"
					printf "Running MIDESP for "$i" .... \n\n"
				
					java -jar Scripts/MIDESP_1.1.jar -threads 70 -out "$i"_Filtered_Pruned.epi -keep 1 -fdr 0.05 -apc 5000 $Source_Folder/TEMP_TPED_FOLDER/"$i".tped $Source_Folder/TEMP_TFAM_FOLDER/"$i".tfam
	
	            else
					
					printf "Analyzing "$i" .. \n"
					head -n5 $INPUT_PHENO_FOLDER/"$i".csv
					# awk -F "\"*,\"*" '{print $3}' $Source_Folder/phenos/"$i".csv $Source_Folder/phenos/"$i".csv 				
					echo "$i has continuous phenotype"
					printf "Running MIDESP.... for "$i" \n\n"
				
					java -jar Scripts/MIDESP_1.1.jar -cont -k 30 -threads 70 -out "$i"_Filtered_Pruned.epi -keep 1 -fdr 0.05 -apc 5000 $Source_Folder/TEMP_TPED_FOLDER/"$i".tped $Source_Folder/TEMP_TFAM_FOLDER/"$i".tfam

				fi
		done

		mv *.epi.sigSNPs midesp_output
		mv *.epi midesp_output
}

main
