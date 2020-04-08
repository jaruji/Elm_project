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

--check askalot for inspiration, i like that idea :) 
--will just show small profile preview with circular avatar and username
--request all users -> interested in avatar, username, verif, registeredAt
--search bar with filtering on input ;)
--pagination might be necessary

pageSize = 25

type alias Model =
  {  
    key: Nav.Key
    , status: Status
    , query: String
    , page: Int
  }

type alias UserPreviewContainer =
  {
    total: Int
    , users: List UserPreview
  }

type alias UserPreview =
  {
    username: String
    , avatar: String
    , verif: Bool
  }

type Status
  = Loading
  | Success (UserPreviewContainer)
  | Failure String

type Msg
  = Test
  | Response (Result Http.Error (UserPreviewContainer))
  | Query String
  | Next
  | Previous
  | Empty

init: Nav.Key -> Maybe Int -> (Model, Cmd Msg)
init key page =
    case page of
        Just int ->
            (Model key Loading "" int, getUsers "" int)
        Nothing ->
            (Model key Loading "" 1, getUsers "" 1)


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Test ->
        (model, Cmd.none)

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
        ({ model | query = query, status = Loading }, getUsers query model.page )

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
                            (List.map showPreview users)
                        , div [ style "margin-bottom" "50px", style "margin-top" "20px" ] [
                            div [ class "help-block" ] [ text ( String.fromInt(model.page) ++ "/" ++ String.fromInt( ceiling ( toFloat container.total / toFloat pageSize ) ) )]
                            , button [ class "btn btn-primary", onClick Previous, if model.page == 1 then disabled True else disabled False ][
                                span [ class "glyphicon glyphicon-chevron-left" ] [] 
                            ]
                            , button [ class "btn btn-primary", onClick Next, if model.page == ceiling ( toFloat container.total / toFloat pageSize ) then disabled True else disabled False ][
                                span [ class "glyphicon glyphicon-chevron-right" ] []
                            ]
                        ]
                    ]
            Failure error ->
                div [ class "alert alert-warning"
                , style "margin" "auto"
                , style "width" "60%" ][
                    text error 
                ]
    ]

showPreview: UserPreview -> Html Msg
showPreview user =
    a [ href ("profile/" ++ user.username)
    , style "display" "inline-block"
    , class "preview"
    , style "height" "250px"
    , style "width" "200px" ][
        img [ 
        src user.avatar
        , class "previewAvatar"
        , height 200
        , width 200
        , style "border-radius" "50%"
        , style "border" "5px solid white"
        , attribute "user-drag" "none"
        , attribute "user-select" "none" ][]
        , div [] [
            text user.username
            , if user.verif == True then 
                span [ class "glyphicon glyphicon-ok-circle", style "color" "green", style "margin-left" "5px" ][]
            else
                span [ class "glyphicon glyphicon-remove-circle", style "color" "red", style "margin-left" "5px" ] []

     ] 
    ] 

userPreviewContainerDecoder: Decode.Decoder UserPreviewContainer
userPreviewContainerDecoder =
    Decode.succeed UserPreviewContainer
        |> required "total" Decode.int
        |> required "users" (Decode.list userPreviewDecoder)

userPreviewDecoder: Decode.Decoder UserPreview
userPreviewDecoder =
    Decode.succeed UserPreview
        |> required "username" Decode.string
        |> optional "profilePic" Decode.string (Server.url ++ "/img/profile/default.jpg")
        |> required "verif" Decode.bool

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
    , expect = Http.expectJson Response userPreviewContainerDecoder
    , timeout = Nothing
    , tracker = Nothing
    }