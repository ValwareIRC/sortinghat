import
  json,
  tables,
  strformat,
  strutils,
  random

import houses
export houses

randomize()

const
  questionsRaw = readFile("./quizes/house.json")
  pointsLookupRaw = readFile("./quizes/house-points-lookup.json")

type
  Question* = object
    question*: string
    answers*: seq[string]
  QuestionGroup = seq[Question]
  Quiz = object
    questions*: seq[QuestionGroup]
  
  Points = ref object
    Gryffindor: float
    Hufflepuff: float
    Ravenclaw: float
    Slytherin: float
  Answers = Table[string, Points]

proc `+=`(p1, p2: Points) =
  p1.Gryffindor = p1.Gryffindor + p2.Gryffindor
  p1.Hufflepuff = p1.Hufflepuff + p2.Hufflepuff
  p1.Ravenclaw = p1.Ravenclaw + p2.Ravenclaw
  p1.Slytherin = p1.Slytherin + p2.Slytherin

let
  questionsJson = parseJson(questionsRaw)
  pointsLookupJson = parseJson(pointsLookupRaw)
  houseQuiz = questionsJson.to(Quiz)
  pointsLookup = pointsLookupJson.to(Answers)

type
  QuizSession* = ref object
    quiz*: Quiz
    currentQuestionGroupIndex: int
    currentQuestionIndex: int
    points: Points

proc newHouseQuiz*(): QuizSession =
  QuizSession(
    quiz: houseQuiz,
    currentQuestionIndex: -1,
    points: Points()
  )

template isFinished*(session: QuizSession): bool =
  session.currentQuestionGroupIndex > session.quiz.questions.high

proc determineHouse*(session: QuizSession): House =
  let maxScore = max(@[
    session.points.Gryffindor,
    session.points.Hufflepuff,
    session.points.Ravenclaw,
    session.points.Slytherin
  ])

  if maxScore == session.points.Gryffindor:
    return Gryffindor
  elif maxScore == session.points.Hufflepuff:
    return Hufflepuff
  elif maxScore == session.points.Ravenclaw:
    return Ravenclaw
  elif maxScore == session.points.Slytherin:
    return Slytherin

proc getCurrentQuestionGroup(session: QuizSession): QuestionGroup =
  return session.quiz.questions[session.currentQuestionGroupIndex]

proc getCurrentQuestion*(session: QuizSession): Question =
  if session.isFinished:
    raise newException(Exception, "There are no more questions in the quiz.")

  let group = session.getCurrentQuestionGroup()
  if session.currentQuestionIndex < 0:
    session.currentQuestionIndex = rand(group.high)
  return group[session.currentQuestionIndex]

proc answerCurrentQuestion*(session: QuizSession, answerIndex: int) =
  ## Answers the current question,
  ## and proceeds to the next question group.
  if session.isFinished:
    raise newException(Exception, "There are no more questions in the quiz.")

  if session.currentQuestionIndex < 0:
    raise newException(Exception, "There is not a current question to answer.")

  let answers = session.getCurrentQuestion().answers
  if answerIndex < 0 or answerIndex > answers.high:
    raise newException(Exception, fmt"Answer index out of range - must be from 0 to {answers.high}.")
  
  let answer = answers[answerIndex]
  var answered = false
  for (key, points) in pointsLookup.pairs():
    if answer.startsWith(key):
      session.points += points
      answered = true
      break

  if not answered:
    raise newException(Exception, "Quiz error - Answer was not found. Please report this issue.")

  # Move on to the next group.
  inc session.currentQuestionGroupIndex
  # De-select the current question when advancing to a new group.
  session.currentQuestionIndex = -1

when isMainModule:
  let session = newHouseQuiz()
  while not session.isFinished:
    let question = session.getCurrentQuestion()
    echo question.question
    echo question.answers
    session.answerCurrentQuestion(0)
    echo ""

  echo session.determineHouse()

