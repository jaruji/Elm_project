module Session exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)

--inspiration from https://github.com/jxxcarlson/elm-shared-login/tree/master/src

type alias Session =
  { 
   username : Maybe String
  } 

type UpdateSession
  = LogIn String
  | LogOut
  | NoUpdate

init : Session
init =
  (Session Nothing)

update: UpdateSession -> Session -> Session
update msg model =
  case msg of
    NoUpdate ->
      model

    LogIn name ->
      { model | username = Just name }

    LogOut ->
      { model | username = Nothing }