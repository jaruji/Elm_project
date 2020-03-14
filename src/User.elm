module User exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (..)

--Model

type alias Model =
  {
    username: String
    , password: String
    , email: String
    , avatar: String
    , verif: Bool
    , history: List String
  }

init: Model
init =
  (Model "" "" "" "" False)