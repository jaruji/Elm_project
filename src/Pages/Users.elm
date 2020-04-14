module Pages.Users exposing(..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import Browser.Dom as Dom
import Task
import Http
import User
import Server
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Json.Decode.Pipeline as Pipeline exposing (required, optional)
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)

pageSize = 20

type alias Model =
  {  
    key: Nav.Key
    , status: Status
    , query: String
    , page: Int
  }

type Status
  = Loading
  | Success (User.PreviewContainer)
  | Failure String

type Msg
  = Test
  | Response (Result Http.Error (User.PreviewContainer))
  | Query String
  | Next
  | Previous
  | Empty
  | Jump Int

init: Nav.Key -> (Model, Cmd Msg)
init key =
    (Model key Loading "" 1, getUsers "" 1)


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Test ->
        (model, Cmd.none)

    Jump int ->
        ({ model | page = int }, Cmd.batch [getUsers model.query int, Task.perform (\_ -> Empty) (Dom.setViewport 0 0)])

    Response response ->
        case response of
            Ok container ->
                let
                    users = container.users
                in
                    if List.isEmpty users == True then
                        ({ model | status = Failure "Query returned no results" }, Cmd.none)
                    else
                        ({ model | status = Success container }, Cmd.none)
            Err log ->
                ({ model | status = Failure "Connection error"}, Cmd.none)

    Query query ->
        ({ model | query = query, status = Loading, page = 1 }, getUsers query 1 )

    Empty ->
        (model, Cmd.none)

    Next ->
        (model, Cmd.batch [ Nav.pushUrl model.key ("/users?page=" ++ String.fromInt(model.page + 1))
        , Task.perform (\_ -> Empty) (Dom.setViewport 0 0) ])

    Previous ->
        if model.page /= 1 then
            (model, Cmd.batch [ Nav.pushUrl model.key ("/users?page=" ++ String.fromInt(model.page - 1))
            , Task.perform (\_ -> Empty) (Dom.setViewport 0 0) ])
        else
            (model, Cmd.none)

view: Model -> Html Msg
view model =
    div[ class "container" ][
        h1[][ text "Check out all the registered users" ]
        , div [ class "form-group row", style "width" "70%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    input [ id "tw"
                    , type_ "text"
                    , class "form-control"
                    , placeholder "Search users"
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
                div[][
                    h4[][ text "Sending the query..." ]
                    , Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                ]
            Success container ->
                let
                    users = container.users
                in
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
                            (List.map User.showPreview users)
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

getUsers: String -> Int -> Cmd Msg
getUsers query page =
    Http.request
    { method = "POST"
    , headers = []
    , url = Server.url ++ "/accounts/query"
    , body = Http.jsonBody <| encodeQuery query page
    , expect = Http.expectJson Response User.decodePreviewContainer
    , timeout = Nothing
    , tracker = Nothing
    }