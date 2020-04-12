port module User exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Time exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Server

--Model

type alias Model =
  {
    username: String
    --, password: String
    , email: String
    , avatar: String
    , bio: String
    , verif: Bool
    , facebook: Maybe String
    , twitter: Maybe String
    , github: Maybe String
    , token: String
    , registered: Time.Posix
  }

type alias Preview =
  {
    username: String
    , avatar: String
    , verif: Bool
  }

type alias PreviewContainer =
  {
    total: Int
    , users: List Preview
  }

decodePreviewContainer: Decode.Decoder PreviewContainer
decodePreviewContainer =
    Decode.succeed PreviewContainer
        |> required "total" Decode.int
        |> required "users" (Decode.list decodePreview)

decodePreview: Decode.Decoder Preview
decodePreview =
    Decode.succeed Preview
        |> required "username" Decode.string
        |> optional "profilePic" Decode.string (Server.url ++ "/img/profile/default.jpg")
        |> required "verif" Decode.bool


--decode logged in user
decodeUser: Decode.Decoder Model
decodeUser =
    Decode.succeed Model
        |> required "username" Decode.string 
        |> required "email" Decode.string
        |> optional "profilePic" Decode.string (Server.url ++ "/img/profile/default.jpg")
        |> optional "bio" Decode.string "No description"
        |> required "verif" Decode.bool
        |> required "facebook" (nullable Decode.string)
        |> required "twitter" (nullable Decode.string)
        |> required "github" (nullable Decode.string)
        |> required "token" Decode.string
        |> required "registeredAt" DecodeExtra.datetime

--if user is not logged in and we only preview their profile
--server wont share user token and email with us - they are hidden
decodeUserNotLoggedIn: Decode.Decoder Model
decodeUserNotLoggedIn = 
    Decode.succeed Model
        |> required "username" Decode.string 
        |> hardcoded "Hidden"
        |> optional "profilePic" Decode.string (Server.url ++ "/img/profile/default.jpg")
        |> optional "bio" Decode.string "No description"
        |> required "verif" Decode.bool
        |> required "facebook" (nullable Decode.string)
        |> required "twitter" (nullable Decode.string)
        |> required "github" (nullable Decode.string)
        |> hardcoded "Hidden"
        |> required "registeredAt" DecodeExtra.datetime

showPreview: Preview -> Html msg
showPreview user =
    a [ href ("profile/" ++ user.username)
    , style "display" "inline-block"
    , class "preview"
    , style "height" "250px"
    , style "width" "200px" ][
        img [ 
        src user.avatar
        , class "previewAvatar"
        , attribute "draggable" "false"
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


port storeToken : Maybe String -> Cmd msg

encodeForStorage: Model -> Cmd msg
encodeForStorage user =
    storeToken (Just user.token)

logout : Cmd msg
logout = 
    storeToken Nothing