module Log exposing (..)

type alias Model =
  {
    type: Type
    , content: String
  }

type Type
--type of log
  = Comment
  | Upload
  | LogIn