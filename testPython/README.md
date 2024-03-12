1- Create virtual enviroment:
>>python -m venv <virtual enviroment name>

2- Activate virtual enviroment:
>>venv/Scripts/activate #En windows
>>source venv/bin/activate #En Linux


3- Change python interpreter:
Press Ctrl+Shift+P, type "Python: Select Interpreter" and select the aforemetioned venv.

4- Init git repository:
>>git init

5- Create gitignore file :
>>type nul > .gitignore

6- Ignore venv folder:
Write inside .gitignore the name of the virtual enviroment

7- Install pydotenv to not storage api keys in plain text cause is a bad programming practice
>>pip install python-dotenv
Create .env file to storage api keys.

8- Instalar libreria web3:
pip install web3

9- Create SSH key pair and save it in github account 
ssh-keygen -t ed25519 -C "Windows_key"
#Let by blanck the paraphrase and name
#The key will by save in Users/<tu usuario>/.ssh/ed25519.pub
#Add the key to the ssh keys on your Github account

***************************************************
Excution:
python .\SLAutoNS.py
