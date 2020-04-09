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
  }

init : Nav.Key -> ( Model, Cmd Msg)
init key =
  ({
    searchValue = ""
    , key = key
  }, Cmd.none)

--Update

type Msg
    = UpdateValue String
    | KeyHandler Int

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    UpdateValue val ->
      ({model | searchValue = val}, Cmd.none)
    KeyHandler key ->
      case key of
        13 ->                       --on Enter down
          case model.searchValue of
            "" ->
              (model, Cmd.none)
            _ ->
              ({ model | searchValue = "" }, Nav.replaceUrl model.key ("/search?q=" ++ model.searchValue))
        _ ->
          (model, Cmd.none)

keyPress : (Int -> msg) -> Attribute msg
keyPress tagger =
  on "keydown" (Decode.map tagger keyCode)

--View
view :  Model -> Html Msg
view model =
    div [ class "form-inline", style "margin-top" "10px" ][
      input [ class "form-control"
      , list "options"
      , type_ "text"
      , placeholder "Search"
      , value model.searchValue
      , autocomplete True
      , onInput UpdateValue
      , keyPress KeyHandler ] []
      , span[ style "margin-top" "10px"
            , style "color" "grey"
            , class "glyphicon glyphicon-search form-control-feedback" ][]
      , datalist [ id "options" ][ text "Ahoj", text "Testing", text "Waduhek"]
      --, onFocus ()
      --, button [ class "btn-primary", onClick Submit ][ text "Search" ]
      --, div[][text ("Currently searching: " ++ model.searchValue)]
      --, div[][text ("Submitted search: " ++ getValue model)]
    ]

getModel: (Model, Cmd Msg) -> Model
getModel (model, cmd) =
  model



--Main

--main =
--  Browser.sandbox { init = init, update = update, view = view }
