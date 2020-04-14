module Pages.Tags exposing (..)

import Browser.Navigation as Nav
import Browser.Dom as Dom
import Task
import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Image
import Server
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)

pageSize = 9

type alias Model =
  {
    query: String
    , status: Status
    , page: Int
  }

type Msg
  = Empty
  | Query String
  | Response (Result Http.Error(Image.PreviewContainer))
  | Jump Int

type Status
  = Loading
  | Success (Image.PreviewContainer)
  | Failure String

init: Nav.Key -> Maybe String -> (Model, Cmd Msg)
init key query =
    case query of
        Just q ->
            (Model q Loading 1, Cmd.batch [Task.perform (\_ -> Empty) (Dom.setViewport 0 0), getImages q 1])
        Nothing ->
            (Model "" Loading 1, Task.perform (\_ -> Empty) (Dom.setViewport 0 0))

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)

        Jump int ->
            if model.query == "" then
                ({ model | page = int, status = Loading }, Cmd.none)
            else
                ({ model | page = int }, Cmd.batch [getImages model.query int, Task.perform (\_ -> Empty) (Dom.setViewport 0 0)])
        Query string ->
            if string == "" then
                ({ model | query = string, status = Loading, page = 1 }, Cmd.none)
            else
                ({ model | query = string, page = 1 }, getImages string model.page)

        Response response ->
            case response of
                Ok container ->
                    ({ model | status = Success container }, Cmd.none)
                Err log ->
                    ({ model | status = Failure ("No results for query \"" ++ model.query ++ "\"") }, Cmd.none)

view: Model -> Html Msg
view model =
    div[][
        h1[][ text "Search images based on tags" ]
        , div [ class "form-group row", style "width" "70%", style "margin" "auto", style "padding-bottom" "15px" ][ 
            div [ class "col-md-offset-2 col-md-8" ][
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
        , hr [ style "margin-top" "-15px" ] []
        , case model.status of
            Loading ->
                text ""
            Success container ->
                let
                    images = container.images
                in
                    case List.length images of
                        0 ->
                            div [ class "alert alert-warning"
                            , style "margin" "auto"
                            , style "width" "60%" ][
                                text ("No results for query \"" ++ model.query ++ "\"")
                            ]
                        _ ->
                            div[][
                                div [ class "alert alert-success"
                                , style "margin" "auto"
                                , style "width" "60%"
                                , style "margin-bottom" "10px" ][
                                    text ("Query returned " ++ String.fromInt(container.total) ++ " results") 
                                ]
                                , div[ class "panel panel-default"
                                , style "margin" "auto"
                                , style "border" "none" ]
                                    (List.map Image.showPreview images)
                                , div [ style "margin-top" "20px" ] [
                                    div [ style "width" "30%"
                                    , style "margin" "auto" ] ((List.range 1 ( ceiling ( toFloat container.total / toFloat pageSize ))) |> List.map (viewButton model) )
                                    , div [ class "help-block" ] [ text ( String.fromInt(model.page) ++ "/" ++ String.fromInt( ceiling ( toFloat container.total / toFloat pageSize ) ) )]
                                ]
                            ]
            Failure error ->
                div [ class "alert alert-warning"
                , style "margin" "auto"
                , style "width" "60%" ][
                    text error 
                ]
    ]

viewButton: Model -> Int -> Html Msg
viewButton model num =
    button[ class "btn btn-default"
    , if model.page == num then
        style "opacity" "0.3"
      else
        style "" ""
    , onClick (Jump num)
    ][
        text (String.fromInt num)
    ]

encodeQuery: String -> Int -> Encode.Value
encodeQuery query page =
    Encode.object 
        [
            ("query", Encode.string query)
            , ("page", Encode.int page)
        ]

getImages: String -> Int -> Cmd Msg
getImages query page =
    Http.request
    { method = "POST"
    , headers = []
    , url = Server.url ++ "/tags/query"
    , body = Http.jsonBody <| encodeQuery query page
    , expect = Http.expectJson Response Image.decodePreviewContainer
    , timeout = Nothing
    , tracker = Nothing
    }
