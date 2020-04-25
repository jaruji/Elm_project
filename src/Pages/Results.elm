module Pages.Results exposing (..)
import Browser
import Browser.Navigation as Nav
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import User
import Image
import Task
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
  | SuccessImage (Image.PreviewContainer)
  | FailureImage

type UserStatus
  = LoadingUser
  | SuccessUser (User.PreviewContainer)
  | FailureUser

init: Maybe String -> (Model, Cmd Msg)
init fragment =
    case fragment of
        Just q ->
            (Model q LoadingImage LoadingUser, Cmd.batch [ Task.perform (\_ -> Empty) (Dom.setViewport 0 0), getUsers q, getPosts q])
        Nothing ->
            (Model "" LoadingImage LoadingUser, Cmd.none)

type Msg
  = ImageResponse (Result Http.Error(Image.PreviewContainer))
  | UsersResponse (Result Http.Error(User.PreviewContainer))
  | Empty

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of 
        Empty ->
            (model, Cmd.none)

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
        div [ class "alert alert-info"
        , style "margin" "auto"
        , style "width" "50%" ][
            text ("Showing results for: \"" ++ model.query ++ "\"")
        ]
        , case model.imageStatus of
            LoadingImage ->
                div[][
                    viewHeading "Images" 0
                    , div[ style "margin-top" "20px" ][
                        Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                    ]
                ]
            FailureImage ->
                div [] [
                    viewHeading "Images" 0
                    , viewFailure "Connection error"
                ]
            SuccessImage container ->
                let
                    images = container.images
                in
                    div[][
                        viewHeading "Images" (List.length images)
                        , if List.isEmpty images then
                            viewFailure (("No results matching query \"" ++ model.query ++ "\""))
                        else
                            div[] (List.map Image.showPreview images)
                    ]
        , case model.userStatus of
            LoadingUser ->
                div[][
                    viewHeading "Users" 0
                    , div[ style "margin-top" "20px" ][
                        Loader.render Loader.Circle {defaultConfig | size = 60} Loader.On
                    ]
                ]
            FailureUser ->
                div [] [
                    viewHeading "Users" 0
                    , viewFailure "Connection error"
                ]
            SuccessUser container ->
                let 
                    users = container.users
                in
                    div[][
                        viewHeading "Users" (List.length users)
                        , if List.isEmpty users then
                            viewFailure (("No results matching query \"" ++ model.query ++ "\""))
                        else
                            div[] (List.map User.showPreview users)
                    ]
        , viewHeading "Tags" 0
        , text "If you wanted to search for tags, click "
        , a [ href ("/tags?q=" ++ model.query)
        , class "preview" ][ text "here" ]
    ]

viewHeading: String -> Int -> Html msg
viewHeading name count =
    div[][
        h1 [] [ text ( name ++ " (" ++ String.fromInt count ++ ")" ) ]
        , hr [ style "width" "50%" 
        , style "margin" "auto"
        , style "margin-bottom" "20px" ] []
    ]

viewFailure: String -> Html msg
viewFailure error = 
    div[ class "alert alert-warning"
    , style "margin-top" "20px"
    , style "width" "40%" 
    , style "margin" "auto" ][
        text error
    ]

getUsers: String -> Cmd Msg
getUsers q =
    Http.get
    { 
    url = Server.url ++ "/accounts/search" ++ "?q=" ++ q
    , expect = Http.expectJson UsersResponse User.decodePreviewContainer
    }

getPosts: String -> Cmd Msg
getPosts q =
    Http.get
    { 
    url = Server.url ++ "/images/search" ++ "?q=" ++ q
    , expect = Http.expectJson ImageResponse Image.decodePreviewContainer
    }