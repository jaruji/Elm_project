module Pages.Users exposing(..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
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

type alias Model =
  {  
    key: Nav.Key
    , status: Status
    , query: String
  }

type alias UserPreview =
  {
    username: String
    , avatar: String
    , verif: Bool
  }

type Status
  = Loading
  | Success (List UserPreview)
  | Failure String

type Msg
  = Test
  | Response (Result Http.Error (List UserPreview))
  | Query String

init: Nav.Key -> (Model, Cmd Msg)
init key =
    (Model key Loading "", getUsers "")


update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Test ->
        (model, Cmd.none)

    Response response ->
        case response of
            Ok users ->
                if List.isEmpty users == True then
                    ({ model | status = Failure "Query returned no results" }, Cmd.none)
                else
                    ({ model | status = Success users }, Cmd.none)
            Err log ->
                ({ model | status = Failure "Connection error"}, Cmd.none)

    Query query ->
        ({ model | query = query, status = Loading }, getUsers query)

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
            Success users ->
                div[][
                    div [ class "alert alert-success"
                    , style "margin" "auto"
                    , style "width" "60%"
                    , style "margin-bottom" "10px" ][
                        text ("Query returned " ++ String.fromInt(List.length users) ++ " results") 
                    ]
                    , div[ class "panel panel-default"
                    , style "margin" "auto"
                    , style "border" "none" ]
                        (List.map showPreview users)
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

userPreviewDecoder: Decode.Decoder UserPreview
userPreviewDecoder =
    Decode.succeed UserPreview
        |> required "username" Decode.string
        |> optional "profilePic" Decode.string (Server.url ++ "/img/profile/default.jpg")
        |> required "verif" Decode.bool

encodeQuery: String -> Encode.Value
encodeQuery query =
    Encode.object 
        [("query", Encode.string query)]

getUsers: String -> Cmd Msg
getUsers query =
    Http.request
    { method = "POST"
    , headers = []
    , url = Server.url ++ "/accounts/query"
    , body = Http.jsonBody <| encodeQuery query
    , expect = Http.expectJson Response (Decode.list userPreviewDecoder)
    , timeout = Nothing
    , tracker = Nothing
    }