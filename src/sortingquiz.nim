import
  json,
  tables,
  strformat,
  random

randomize()

const
  questionsRaw = readFile("./quizes/house.json")
  pointsLookupRaw = readFile("./quizes/house-points-lookup.json")

type
  Question* = object
    question: string
    answers: seq[string]
  QuestionGroup = seq[Question]
  Quiz = object
    questions: seq[QuestionGroup]
  
  Points = object
    Gryffindor: float
    Ravenclaw: float
    Hufflepuff: float
    Slytherin: float

  Answers = Table[string, Points]

let
  questionsJson = parseJson(questionsRaw)
  pointsLookupJson = parseJson(pointsLookupRaw)
  houseQuiz = questionsJson.to(Quiz)
  pointsLookup = pointsLookupJson.to(Answers)

type
  QuizSession* = ref object
    quiz: Quiz
    currentQuestionGroupIndex: int
    currentQuestionIndex: int
    points: Points

proc newHouseQuiz(): QuizSession =
  QuizSession(
    quiz: houseQuiz,
    currentQuestionIndex: -1
  )

proc getCurrentQuestionGroup(session: QuizSession): QuestionGroup =
  return session.quiz.questions[session.currentQuestionGroupIndex]

proc getCurrentQuestion(session: QuizSession): Question =
  if session.currentQuestionGroupIndex > session.quiz.questions.high:
    raise newException(Exception, "There are no more questions in the quiz.")

  let group = session.quiz.questions[session.currentQuestionGroupIndex]
  if session.currentQuestionIndex < 0:
    session.currentQuestionIndex = rand(group.high)
  return group[session.currentQuestionIndex]

proc answerCurrentQuestion(session: QuizSession, answerIndex: int) =
  ## Answers the current question,
  ## and proceeds to the next question group.
  if session.currentQuestionIndex < 0:
    raise newException(Exception, "There is not a current question to answer.")

  let answers = session.getCurrentQuestion().answers
  if answerIndex < 0 or answerIndex > answers.high:
    raise newException(Exception, fmt"Answer index out of range - must be from 0 to {answers.high}.")
  
  let answer = answers[answerIndex]
  # TODO: How to lookup the answer in pointsLookup?
  # Keys in pointsLookup start with the full answers.

  # Move on to the next group.
  inc session.currentQuestionGroupIndex
  # De-select the current question when advancing to a new group.
  session.currentQuestionIndex = -1

when isMainModule:
  let session = newHouseQuiz()
  echo session.getCurrentQuestion()
  echo session.getCurrentQuestion()
  echo session.getCurrentQuestion()

