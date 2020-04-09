module Pages.Results exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import User
import Image
import Server
import Json.Encode as Encode exposing (..)
import Json.Decode as Decode
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)


--the issue is that the result is nested...
    
type alias Model =
  {
    query: String
    , imageStatus: ImageStatus
    , userStatus: UserStatus
  }

type ImageStatus
  = LoadingImage
  | SuccessImage (List Image.Preview)
  | FailureImage

type UserStatus
  = LoadingUser
  | SuccessUser (List User.Preview)
  | FailureUser

init: Maybe String -> (Model, Cmd Msg)
init fragment =
    case fragment of
        Just q ->
            (Model q LoadingImage LoadingUser, Cmd.batch [getUsers q, getPosts q])
        Nothing ->
            (Model "" LoadingImage LoadingUser, Cmd.none)

type Msg
  = ImageResponse (Result Http.Error(List Image.Preview))
  | UsersResponse (Result Http.Error(List User.Preview))

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of 
        ImageResponse response ->
            case response of
                Ok images ->
                    ({ model | imageStatus = SuccessImage images }, Cmd.none)
                Err log ->
                    ({ model | imageStatus = FailureImage }, Cmd.none)

        UsersResponse response ->
            case response of
                Ok users ->
                    ({ model | userStatus = SuccessUser users }, Cmd.none)
                Err log ->
                    ({ model | userStatus = FailureUser }, Cmd.none)

view: Model -> Html Msg
view model =
    div [][
        text ("Showing results for: \"" ++ model.query ++ "\"")
        , h1 [] [ text "Images" ]
        , hr [ style "width" "50%" 
        , style "margin" "auto"
        , style "margin-bottom" "20px" ] []
        , case model.imageStatus of
            LoadingImage ->
                div[ style "margin-top" "20px" ][
                    Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                ]
            FailureImage ->
                viewFailure model.query
            SuccessImage images ->
                div[][

                ]
        , h1 [] [ text "Users" ]
        , hr [ style "width" "50%" 
        , style "margin" "auto"
        , style "margin-bottom" "20px" ] []
        , case model.userStatus of
            LoadingUser ->
                div[ style "margin-top" "20px" ][
                    Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                ]
            FailureUser ->
                viewFailure model.query
            SuccessUser users ->
                div[] (List.map User.showPreview users)
    ]

viewFailure: String -> Html msg
viewFailure query = 
    div[ class "alert alert-warning"
    , style "margin-top" "20px"
    , style "width" "50%" 
    , style "margin" "auto" ][
        text ("No results matching query \"" ++ query ++ "\"")
    ]

encodeQuery: String -> Encode.Value
encodeQuery q =
    Encode.object [("query", Encode.string q)]

getUsers: String -> Cmd Msg
getUsers q =
    Http.post
    { 
    url = Server.url ++ "/accounts/query"
    , body = Http.jsonBody <| encodeQuery q
    , expect = Http.expectJson UsersResponse (Decode.list User.decodePreview)
    }

getPosts: String -> Cmd Msg
getPosts q =
    Http.post
    { 
    url = Server.url ++ "/images/get"
    , body = Http.jsonBody <| encodeQuery q
    , expect = Http.expectJson ImageResponse (Decode.list Image.decodePreview)
    }