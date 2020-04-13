module Pages.Tags exposing (..)

import Browser.Navigation as Nav

type alias Model =
  {

  }

type Msg
  = Test

init: Nav.Key -> Maybe String -> Maybe Int -> (Model, Cmd Msg)
init key query page =
    (Model, Cmd.none)
