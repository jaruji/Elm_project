module Session exposing (..)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import User exposing (..)

--inspiration from https://github.com/jxxcarlson/elm-shared-login/tree/master/src

type alias Session =
  { 
   user : Maybe User.Model
  } 

type UpdateSession
  = Update User.Model
  | NoUpdate

init: Session
init =
  (Session Nothing)

set: User.Model -> Session
set model =
  (Session (Just model)) 

update: UpdateSession -> Session -> Session
update msg model =
  case msg of
    NoUpdate ->
      model

    Update usr ->
      { model | user = Just usr }