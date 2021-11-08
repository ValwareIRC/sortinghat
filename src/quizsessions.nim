import
  houses,
  sortingquiz,
  strformat

var quizSessions: Table[string, QuizSession]

proc startHouseQuiz*(nick: string) =
  if quizSessions.hasKey(nick):
    raise newException(Exception, fmt"{nick} is already taking a quiz.")
  quizSessions[nick] = newHouseQuiz()

proc getSession*(nick: string): QuizSession =
  if not quizSessions.hasKey(nick):
    return nil
  return quizSessions[nick]

proc closeQuiz*(nick: string) =
  quizSessions.del(nick)

