#!/bin/bash

# Sort Directory By Timestamp by Matthew Relph
# v 1.00
# Bash Script Version
#
#
# Taking a directory full of files, and putting them in folders based on the date of their last modification
# Works good for lots of things, logs, pictures, piles of HL7 pharmacy requests, you name it!
# 
#
# Some error checking. Should stop and report to shell on any error
# As always, use at your own risk
# 
# 1st Argument=Source Path
# 2nd Argument=Destination Path
# 3rd Argument=Option Flags (-xxxx)
#
# Example use (In Powershell):
# scriptName Source Destination -xxxx
# 
#
# Possible future additions: Filter by extension, relative paths, more error checking



# Begin Functions
function PrintArgs() 
{

    printf "We are looking for 3 parameters. \n Argument #1=Source Directory \n Argument #2=Destination Directory \n Argument #3=Options Flags \n"
    printf "\t-c=Copy to new directory only (Leaves Originals) \n\t-v=Move to new directory\n"
    printf "\t-n=No prompts (overrides other options) \n\t-p=Prompt at conflicts\n"
    printf "\t-y=Split By Year  \n\t-m=Split By Month \n\t-d=Split By Day \n"
    printf "\t-o=Default action is to overwrite on conflict \n\t-x=Default action is to make a copy on conflict\n"
    printf " While you must pick options, combinations can include -cnyo, -vpdn, etc.\n"
    printf "\n The correct syntax is \"scriptName Source Destination -xxxx\" \n"

    printf "\nYou passed %i arguments.\n" "$numArgs"
    for (( i=0; i < numArgs; i++));
    do
		printf "\tArg# %i : %s \n" $((i+1)) "${args[$i]}"
    done
}


function checkArgs()
{
    
    
    #Need 3 arguments

    if [[ $numArgs != 3 ]]
    then
        PrintArgs
        continueProgram="false"
    else
        #Check options list
        options=${args[2]}
		#printf "Options: $options\n"

		if [[ $options == -* ]]
        then
            #printf "Options String init"
            optionsFlag="true"

			#if 	[[ $options =~ "c" ]] || [[ $options =~ "C" ]]
			if 	[[ $options =~ [c*C*] ]]
            then
                moveFlag="false"
            fi

			if 	[[ $options =~ [v*V*] ]]
            then
                moveFlag="true"
            fi
			
			if 	[[ $options =~ [n*N*] ]]
            then
                promptFlag="false"
            fi

			if 	[[ $options =~ [p*P*] ]]
            then
                promptFlag="true"
            fi
			
			if 	[[ $options =~ [d*D*] ]]
            then
                sortBy="d"
            fi

			if 	[[ $options =~ [m*M*] ]]
            then
                sortBy="m"
            fi

			if 	[[ $options =~ [y*Y*] ]]
            then
                sortBy="y"
            fi

			if 	[[ $options =~ [o*O*] ]]
            then
                overwriteFlag="true"
            fi

			if 	[[ $options =~ [x*X*] ]]
            then
                overwriteFlag="false"
            fi
        else
            #printf "Options String fail"
            optionsFlag="false"
            continueProgram="false"
        fi
        
        #Check Source Directory
		sourcePath="${args[0]}"
		printf "Source Directory:\n\t%s\n" "$sourcePath"
        if [ -d "$sourcePath" ]
		then
			printf "\tSource Path exists\n"
		else
			printf "\tSource Path does not exist - Cannot Continue\n"

			continueProgram="false"
		fi
        
        #Check Destination Directory
		destinationPath="${args[1]}"
        printf "Destination Directory:\n\t%s\n" "$destinationPath"
		
		if [ -d "$destinationPath" ]
		then
			printf "\tDestination Path exists\n"
		else
			makeDir="n"
			if [ $promptFlag = "true" ]
			then
				#Prompt to make the directory
				
				printf "\tAttempt to make new directory \n\t\t\'%s\'? (y/n) " "$destinationPath"
				read -r makeDir
				printf "\n"
			else
				#Make the directory without the prompt, if prompts are turned off
				makeDir="y"
			fi
			if [[ $makeDir == "y" ]] || [[ $makeDir == "Y" ]]
			then
				printf "\tMaking directory: %s\n" "$destinationPath"
				mkdir -p "$destinationPath"
			else
				printf "\tDestination Path is not valid - Cannot Continue\n"
				continueProgram="false"
			fi
		fi

        printf "Options: %s \n" "${args[2]}"
        if [[ $optionsFlag == "false" ]]
        then
            printf "\tOptions not detected - Using Defaults\n"
        fi
        printf "\tMove= %s \n" $moveFlag
        printf "\tPrompt= %s \n" $promptFlag
        case $sortBy in
            "d") 
				printf "\tSort By= Day \n"
				;;
            "m") 
				printf "\tSort By= Month \n"
				;;
            "y") 
				printf "\tSort By= Year \n"
				;;
		esac
        if [[ $overwriteFlag == "true" ]]
        then
            printf "\tDefault Action= Overwrite \n" 
        else
            printf "\tDefault Action= Make Copy \n" 
        fi
                
    fi

}

function mainTask()
{
    printf "\nPreparing to Copy...\n"
    #Get List of Files
    fileCopyList=("$sourcePath"/*)
	
	
    for source in "${fileCopyList[@]}"
    do
        #Get File Modified Date
		copyFile=$(basename "$source")
		fileYear=$( date -r "$source" +"%Y")
		fileMonth=$( date -r "$source" +"%m")
		fileDay=$( date -r "$source" +"%d")

        #Get year string and append to path
        extendedDestinationPath="${destinationPath}/${fileYear}"

        if [[ $sortBy == "d" ]] || [[ $sortBy == "m" ]]
        then
           #Get month string and append to path
           extendedDestinationPath="${extendedDestinationPath}/${fileMonth}"
        fi
        if [[ $sortBy == "d" ]]
        then
           #Get year string and append to path
           extendedDestinationPath="${extendedDestinationPath}/${fileDay}"
        fi       

        destination="${extendedDestinationPath}/${copyFile}"
		# Make the necessary directory structure
		if [[ ! ( -d "$extendedDestinationPath" ) ]]
		then
			printf "Making directory: %s \n" "$extendedDestinationPath"
			mkdir -p "$extendedDestinationPath"
		fi  

        # Now we check if the file exists, and determine what we need to do on conflict
        conflictFlag="false"

		if [[ -f "$destination" ]]
		then
			conflictFlag="true"
			# File already exists, we need to refer to the options to see what we do next
		fi

        # If prompts are on, we check with the user
        overwriteNext=$overwriteFlag
        if [[ $conflictFlag == "true" ]] && [[ $promptFlag == "true" ]]
        then
			printf "\n\"%s\" already exists \nOverwrite or Make New Copy? (o/c) " "$destination"
            read -r conflictAction
            if [[ $conflictAction == "o" ]] || [[ $conflictAction == "O" ]]
            then
                overwriteNext="true"
            elif [[ $conflictAction == "c" ]] || [[ $conflictAction == "C" ]]
			then
                overwriteNext="false"
            fi
        fi

        # During conflict If we choose to copy, we make a new copy with a unique file name, otherwise we continue on and overwrite the file
        if [[ $conflictFlag == "true" ]] && [[ $overwriteNext == "false" ]]
        then
			#Check if file already exists . We will keep up to 255 copies of files of the same name in the same directory. Beyond that, it is just ridiculous
			fileVersion=0
			while [[ -f "$destination" ]] && [[ $fileVersion -lt 255 ]]
			do     
				destination="${extendedDestinationPath}/(${fileVersion})${copyFile}"
				fileVersion=$((fileVersion+1))

			done 
        fi

        # Final file copy - Preserve Timestamps
		cp -p "$source" "$destination"
    done
    printf "Copy Complete\n"

    # Remove source files if we are setup to move instead of just copy. 
    # Only remove files from the list we copied (Some files may have been added since we started)
    if [[ $moveFlag == "true" ]]
    then
        printf "Removing Originals from Source Directory..."
        for removeFile in "${fileCopyList[@]}"
        do
			rm "$removeFile"
        done
        printf "Removals Complete\n"
    fi
    printf "Sorting Complete\nEnd Script\n"


}
# End functions


# Begin program

# Stop script if a command fails
set -e 

clear
printf "This script organizes a directory of files into subdirectories by date. \nIt will move your files, if you have the proper permissions, so be careful!\n\n"

#Collect Arguments
args=("$@")
numArgs=$#


#Options Defaults - Least destructive options
promptFlag="true"
moveFlag="false"
overwriteFlag="false"
sortBy=d

continueProgram="true"

#PrintArgs

checkArgs

startMove=""

if [[ $promptFlag == "true" ]] && [[ $continueProgram == "true" ]]
then
    while [[ $startMove != "y" ]] && [[ $startMove != "Y" ]] && [[ $startMove != "n" ]] && [[ $startMove != "N" ]]
    do
		printf "\nDo you wish to continue? (y/n) "
		read -r startMove
    done

    if [[ $startMove == "n" ]] || [[ $startMove == "N" ]]
    then
        continueProgram="false"
    fi
fi

if [[ $continueProgram == "true" ]]
then
    mainTask
else
    printf "\n Cannot Continue\n End Script\n"
fi

exit 0
# End program
# End script







