module Components.SearchBar exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import FeatherIcons as Icons

type alias Model =
  {
    searchValue: String
    , key: Nav.Key
    , state: State
  }

init : Nav.Key -> ( Model, Cmd Msg)
init key =
  (Model "" key Invalid, Cmd.none)

type Msg
  = UpdateValue String
  | KeyHandler Int

type State
  = Valid
  | Invalid

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateValue val ->
      if String.length val < 2 then
        ({ model | searchValue = val, state = Invalid }, Cmd.none)
      else
        ({ model | searchValue = val, state = Valid }, Cmd.none)
    KeyHandler key ->
      case key of
        13 ->                       --on Enter down
          case model.state of
            Invalid ->
              (model, Cmd.none)
            Valid ->
              ({ model | searchValue = "", state = Invalid }, Nav.replaceUrl model.key ("/search?q=" ++ model.searchValue))
        _ ->
          (model, Cmd.none)

keyPress : (Int -> msg) -> Attribute msg
keyPress tagger =
  on "keydown" (Decode.map tagger keyCode)

--View
view :  Model -> Html Msg
view model =
    div [ class "form-inline"
    , style "margin-top" "10px" ][
      input [ class "form-control"
      , type_ "text"
      , placeholder "Search"
      , value model.searchValue
      , onInput UpdateValue
      , keyPress KeyHandler ] []
      , span[ style "margin-top" "10px"
      , style "color" "grey"
      , class "glyphicon glyphicon-search form-control-feedback" ][]
    ]

getModel: (Model, Cmd Msg) -> Model
getModel (model, cmd) =
  model