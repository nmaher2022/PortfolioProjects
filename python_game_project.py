# This Python program offers the option of playing either a maths or binary game
# where the numbers of questions selected can be between 1 and 10.
# It handles exceptions if the wrong format is input.


from os import remove, rename
from random import randint

# Function for printing the game instructions 
def print_instructions(instruction):
    print(instruction)

#  Function for printing a prompt and taking the input
def input_prompt(var_prompt):
    return input(var_prompt)

#  Function for printing strings explaining what the number of questions are set to
#  when the user gives a number outside of the given range.
def explain_num_of_questions(val):
    if val < 1:
        print('Minimum Number of Questions=1')
        print('Hence, number of questions will be set to 1.')
    elif val > 10:
        print('Maximum Number of Questions=10')
        print('Hence, number of questions will be set to 10.')
    


#  Function for getting the user's score given a user name.
#  The try statement is for the case where the user_score file does not exist yet.

def get_user_score(user_name):
    try:
        f = open('user_scores.txt','r') 
        content = [] 
        user_score =-1 # Assigns default value to user_score

        for line in f:
            content.append(line.split(', ')) # Splits each line into strings by comma. 
            if user_name == line.split(', ')[0]: # Checks if the user name given matches the name on each line.
                user_score = line.split(', ')[1] # If the name matches the score is assigned.
                f.close() # The file is closed and the user's score is returned.
                return user_score.rstrip('\n')
                break
        if user_score ==-1:
            f.close()
            return '-1'
        
    except IOError:
        print('No score file exists yet')
        f = open('user_scores.txt','w')
        f.close()
        return '-1'
        
# Function for updating the user's score
def update_user_score(new_user, user_name, score):
    if new_user == True:
        f = open('user_scores.txt','a')
        f.write(user_name +', '+ score + '\n') 
        f.close()
    else:
        ftemp = open('user_scores.tmp','w') # Creates temporary  file in order to update a score of a previous user
        f1 = open('user_scores.txt','r')

        for line in f1:
            content = line.split(',')
            if user_name == content[0]:
                ftemp.write(user_name +', '+ score + '\n')
            else:  
                ftemp.write(line)
        ftemp.close()
        f1.close()
        remove('user_scores.txt') #  Deletes old text_scores file
        rename('user_scores.tmp','user_scores.txt') # Renames temporary file as text_scores file


# Class of game which initialises the number of questions
# and requires the number of questions to be between 0 and 10 with the setter property.
class Game:
    
    def __init__(self,no_of_questions=0):
        self._no_of_questions=no_of_questions
    
    @property 
    def no_of_questions(self):
        return self._no_of_questions
    
    @no_of_questions.setter
    def no_of_questions(self, value):
        if value < 1:
            self._no_of_questions = 1
        elif value > 10:
            self._no_of_questions = 10
        else: 
            self._no_of_questions = value
            

#  Class defines the actions required for the binary game
#  The user is asked to convert a random number into binary format.
#  If they give a correct answer their score increases by one, otherwise their score remains the same
#  and the correct answer is provided.
class BinaryGame(Game):
    def generate_questions(self):
        score = 0
        for i in range(self.no_of_questions):
            base10 = randint(1,100)
            user_result = input('Convert the number %d to binary '%base10) # gives user input as a string
            
            while True:
                try:
                    # Tells Python that the number is base 2, then int converts it to base 10
                    answer = int(user_result,base=2) 
                    if answer == base10:
                        print('The answer is correct.')
                        score += 1
                        break
                    else:
                        print('That was an incorrect answer. The correct answer is {0:b}.'.format(base10))
                        break          
                        
                except Exception as e:
                    print('The error message is ',e)
                    user_result = input_prompt('This is not a binary number. Please enter a new number')
                   
        return score
        

#  Class defines the actions required for the math game
#  The user is asked to calculate the result of the mathematical operations given.
#  If they give a correct answer their score increases by one, otherwise their score remains the same
#  and the correct answer is provided.
class MathGame(Game):
    
    def generate_questions(self):
        score = 0
        number_list = [0]*5
        symbol_list = ['']*4
        operator_dict = {1:'+',2:'-',3:'*',4:'**'}

        for i in range(self._no_of_questions):
            for i,j in enumerate(number_list):
                number_list[i] = randint(1,9)
            for i,j in enumerate(symbol_list):
                symbol_list[i] = operator_dict[randint(1,4)]
                if i>0 and symbol_list[i-1] == '**' and symbol_list[i] == '**':
                    symbol_list[i] = operator_dict[randint(1,3)]
           
            question_string = str(number_list[0])
            for i,j in enumerate(symbol_list):
                question_string = question_string + symbol_list[i] + str(number_list[i+1])
            
            result = eval(question_string)
            question_string = question_string.replace('**','^')
            user_result = input_prompt('Evaluate the expression: %s '%question_string) # gives user input as a string

            while True:
                try:
                    answer = int(user_result)
                    if result == answer:
                        print('The answer is correct.')
                        score += 1
                        break
                    else:
                        print('That was an incorrect answer. The correct answer is %d'%result)
                        break           
                        
                except Exception as e:
                    print('The error message is ',e)
                    user_result = input_prompt('This is an invalid input. It should be a number. Please enter a new number')
                   
        return score
    


#  This try statement combines all the previous classes and functions to interact with the user
try:
    mathInstructions = '''In this game, you will be a given a simple arithmetic question. 
    Each correct answer gives you one mark. No mark is deducted for wrong answers.'''

    binaryInstructions = '''In this game, you will be a given a number in base 10.
    Your task is to convert this number to base 2. 
    Each correct answer gives you one mark. 
    No mark is deducted for wrong answers.'''

    bg = BinaryGame()
    mg = MathGame()

   # prompt = 'What is your username?'
   # user_name = input(prompt)
    user_name = input_prompt('What is your username?')
    score = int(get_user_score(user_name))
    if score == -1:
        new_user = True
        score = 0
    else:
        new_user = False
    print('Welcome %s, your score is %d'%(user_name,score))
    user_choice = 0
    num_games = 0

    while user_choice != '-1':
        gamechoice = input_prompt('What game would you like to play: Binary (press b) or Math(press m)?')
        while gamechoice != 'b' and gamechoice != 'm':
            gamechoice = input_prompt('That is an invalid choice. The game options are Binary (press b) or Math (press m)?')
        user_choice = '-1'
        numprompt = input_prompt('How many questions do you want per game (1 to 10)')

        while True:
            try:
                num = int(numprompt) 
                break
            except Exception as e:
                print('The error message is ',e)
                user_result = input_prompt('This is an invalid input. It should be a number. Please enter a new number')#gives user input as a string
                break 

        if gamechoice == 'm':
            mg.no_of_questions = num 
           # message = mg.some_method(...)
            #print(message)
            print_instructions(mathInstructions)
            score = score + mg.generate_questions()
        elif gamechoice == 'b':
            bg.no_of_questions = num 
            print_instructions(binaryInstructions)
            score = score + bg.generate_questions()

        print('\n Your current score is %d'%(score))
        num_games +=1
        user_choice = input('\nPress Enter to continue or -1 to end :')
        if num_games > 1:
            new_user = False
        update_user_score(new_user, user_name, str(score))
       
except Exception as e:
    print('An error has occurred. The program will stop.')
    print('Error: ', e)
