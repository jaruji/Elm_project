module Components.SearchBar exposing (..)
--module HomePage exposing (main)
--import Keyboard.Event as Keyboard
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import FeatherIcons as Icons


{-
dropdown(autocomplete), escape cancels dropdown
, searchHistory when first focused
-}

--Model

type alias Model =
  {
    searchValue: String
    , finalValue: String
  }

init : Model
init =
  {
    searchValue = ""
    , finalValue = ""
  }

--Update

type Msg
    = UpdateValue String
    | Submit
    | KeyHandler Int

update : Msg -> Model -> Model
update msg model =
  case msg of
    UpdateValue val ->
      ({model | searchValue = val})
    Submit ->
      ({model | finalValue = model.searchValue
      , searchValue = ""
      })
    KeyHandler key ->
      case key of
      13 ->                       --on Enter down
        ({ model | finalValue = model.searchValue
        , searchValue = ""
         })
      _ ->
        model

getValue : Model -> String
getValue =
  .finalValue

keyPress : (Int -> msg) -> Attribute msg
keyPress tagger =
  on "keydown" (Json.map tagger keyCode)

--View
view :  Model -> Html Msg
view model =
    div [ class "form-inline", style "margin-top" "10px" ][
      input [ class "form-control"
      , type_ "text"
      , placeholder "Search"
      , value model.searchValue
      , onInput UpdateValue
      , keyPress KeyHandler ] []
      , span[ style "margin-top" "10px"
            , style "color" "grey"
            , class "glyphicon glyphicon-search form-control-feedback"
            , onClick Submit ][]
      --, onFocus ()
      --, button [ class "btn-primary", onClick Submit ][ text "Search" ]
      --, div[][text ("Currently searching: " ++ model.searchValue)]
      --, div[][text ("Submitted search: " ++ getValue model)]
    ]



--Main

--main =
--  Browser.sandbox { init = init, update = update, view = view }
