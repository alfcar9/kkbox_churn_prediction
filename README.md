Data mining
Final Proyect

Team members: Lorena Mejía, Alfredo Carrillo, Ricardo Figueroa

Requisites:
1. python3

To automatically download data from the contest, the following actions must be followed:

1. Install kaggle's CLI with the command `sudo pip3 install kaggle` 
3. Make an API token from kaggle by visting your profile at the url `https://www.kaggle.com/[USER]/account` and save at your own directory @ `~/.kaggle/kaggle.json`
4. For security purposes, execute the following command to change the .json file token permissions `chmod 600 /home/ricardo/.kaggle/kaggle.json`
5. Run the command `kaggle competitions download -c kkbox-churn-prediction-challenge`.
6. After all these steps and also after receiving the data from the Kaggle interface, there is a need to unzip the received files with the following command `unzip all.zip -d .`
7. All the unziped files are presented in format '7z', so there is the need to decompress them by executing the following script: `./descomprimir.sh`. This script will also move all the `.csv` files to the `./data` and remove all the `7z` files to clean the directory.

