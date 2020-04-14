module Pages.Tags exposing (..)

import Browser.Navigation as Nav
import Browser.Dom as Dom
import Task
import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

type alias Model =
  {
    query: String
    , page: Int
  }

type Msg
  = Search
  | Empty
  | Query String

init: Nav.Key -> Maybe Int -> Maybe String -> (Model, Cmd Msg)
init key page query =
    case query of
        Just q ->
            case page of
                Just int ->
                    (Model q int, Task.perform (\_ -> Empty) (Dom.setViewport 0 0))
                Nothing ->
                    (Model q 1, Task.perform (\_ -> Empty) (Dom.setViewport 0 0))
        Nothing ->
            case page of
                Just int ->
                    (Model "" int, Task.perform (\_ -> Empty) (Dom.setViewport 0 0))
                Nothing ->
                    (Model "" 1, Task.perform (\_ -> Empty) (Dom.setViewport 0 0))

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)
        Query string ->
            ({ model | query = string }, Cmd.none)
        Search ->
            (model, Cmd.none)

view: Model -> Html Msg
view model =
    div[][
        h1[][ text "Search images based on tags" ]
        , div [ class "form-group row", style "width" "70%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    input [ type_ "text"
                    , class "form-control"
                    , placeholder "Search tags"
                    , Html.Attributes.value model.query
                    , onInput Query ] []
                    , span[ style "color" "grey"
                    , class "glyphicon glyphicon-search form-control-feedback"
                    ][]
                ]
            ]
        ] 
    ]