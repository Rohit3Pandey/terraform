import os 
import time


def Directory():
    try: 
        folders = input("Please provide folders name with spaces in between: ").split()
        for folder in folders:
            files = os.listdir(folder)  
            print("Results for" + " ", folder)
            for file in files:
                print(file) 
    except FileNotFoundError:    
        print("You have entered a invalid folder name.")
        print("Program RE-STARTS in 5 seconds:")
        time.sleep(5)
        Directory()

        
    
Directory()

