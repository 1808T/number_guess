#! /bin/bash
echo -e "\n~~~ Number Guessing Game!!! ~~~\n"
PSQL="psql -U freecodecamp -d number_guess -t --no-align -c"

GENERATE_SECRET_NUMBER() {
  SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))
  NUMBER_OF_TRIES=0
}

COUNT_NUMBER_OF_TRIES() {
  NUMBER_OF_TRIES=$(($NUMBER_OF_TRIES + 1))
}

IDENTIFY_USER() {
  if [[ ! -z $1 ]]
  then
    echo "$1"
  fi

  echo "Enter your username:"
  read USERNAME
  if [[ -z $USERNAME || ${#USERNAME} -gt 22 ]]
  then
    echo "Invalid username. Must be 1 - 22 characters."
  else
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
    if [[ -z $USER_ID ]]
    then
      INSERT_NEW_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
      if [[ $INSERT_NEW_USER_RESULT == "INSERT 0 1" ]]
      then
        USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
        echo "Welcome, $USERNAME! It looks like this is your first time here."
      else
        IDENTIFY_USER "Something went wrong. Please try again!"
      fi
    else
      TOTAL_GAMES_PLAYED=$($PSQL "SELECT COUNT(game_id) FROM games GROUP BY user_id HAVING user_id=$USER_ID")
      LOWEST_GUESSES=$($PSQL "SELECT MIN(number_of_tries) FROM games WHERE user_id=$USER_ID")
      if [[ -z $TOTAL_GAMES_PLAYED || -z $LOWEST_GUESSES ]]
      then
        echo "Welcome back, $USERNAME! You haven't played any game. Wanna try one?"
      else
        echo "Welcome back, $USERNAME! You have played $TOTAL_GAMES_PLAYED games, and your best game took $LOWEST_GUESSES guesses."
      fi
    fi
  fi
}

GUESS_NUMBER() {
  if [[ -z $1 ]]
  then
    echo "Guess the secret number between 1 and 1000:"
  else
    echo "$1"
  fi

  read INPUT_NUMBER
  if [[ ! $INPUT_NUMBER =~ ^[0-9]+$ ]]
  then
    GUESS_NUMBER "That is not an integer, guess again:"
  else
    COUNT_NUMBER_OF_TRIES
    if [[ $INPUT_NUMBER -lt $SECRET_NUMBER ]]
    then
      GUESS_NUMBER "It's higher than that, guess again:"
    elif [[ $INPUT_NUMBER -gt $SECRET_NUMBER ]]
    then
      GUESS_NUMBER "It's lower than that, guess again:"
    else
      echo "You guessed it in $NUMBER_OF_TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"
      INSERT_GAME_RESULT=$($PSQL "INSERT INTO games(user_id, number_of_tries) VALUES($USER_ID, $NUMBER_OF_TRIES)")
    fi
  fi
}

START_GAME() {
  GENERATE_SECRET_NUMBER
  IDENTIFY_USER
  GUESS_NUMBER
}

START_GAME