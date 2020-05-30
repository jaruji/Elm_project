module Components.SearchBar exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import FeatherIcons as Icons

--Model
--searchValue: current value showing up in search bar
--key: used to manipulate url, needs to be obtained from parent (file that used this module)
--state: state of searchbar, tells us if search can be submitted
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

--states of SearchBar
type State
  = Valid
  | Invalid

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateValue val ->
      {--
        If our query is too short, we won't be allowed to submit it.
        This is a precaution against people who would search "", because
        the query would return a massive amount of matches
      --}
      if String.length val < 2 then
        ({ model | searchValue = val, state = Invalid }, Cmd.none)
      else
        ({ model | searchValue = val, state = Valid }, Cmd.none)
    KeyHandler key ->
      case key of
        --Submit query on enter press
        13 ->                       
          case model.state of
            Invalid ->
              (model, Cmd.none)
            Valid ->
              {--
                If search was valid, we replace the url by using Nav.replaceUrl (doesn't leave multiple
                traces in history). We also reset the SearchBar.
              --}
              ({ model | searchValue = "", state = Invalid }, Nav.replaceUrl model.key ("/search?q=" ++ model.searchValue))
        _ ->
          (model, Cmd.none)

keyPress : (Int -> msg) -> Attribute msg
keyPress tagger =
  --Listen to keydown event and get the code of key pressed
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