module Pages.Profile.Settings exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import User
import Server
import Social
import Http
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Json.Encode as Encode exposing (..)

{--
    Tab of profile that shows up only if the user is logged in and is viewing his own profile.
    Allows user to change his bio and social network accounts.
--}

type alias Model =
  {
    user: User.Model
    , bio: String
    , facebook: String
    , twitter: String
    , github: String
    , warning: List String
  }

init: User.Model -> (Model, Cmd Msg)
init user =
    --on init need to fill inputs with values obtained from server during login
    (Model user user.bio (Social.getLink user.facebook) (Social.getLink user.twitter) (Social.getLink user.github) [], Cmd.none)

type Msg
  = Empty
  | Bio String
  | Facebook String
  | Twitter String
  | Github String
  | UpdateSettings
  | UpdateResponse  (Result Http.Error())

type Status
  = Loading
  | Success
  | Failure 

getModel: (Model, Cmd Msg) -> Model
getModel (model, cmd) =
    model

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)

        UpdateResponse response ->
            case response of
                Ok _ -> 
                    (model, Nav.reload)
                Err log ->
                    (model, Cmd.none)

        Bio string ->
            ({model | bio = string}, Cmd.none)

        Facebook string ->
            ({model | facebook = string}, Cmd.none)

        Twitter string ->
            ({model | twitter = string}, Cmd.none)

        Github string ->
            ({model | github = string}, Cmd.none)
            
        UpdateSettings ->
            --update valid only if the social network URL's entered are valid,
            --otherwise warning pops up
            if Social.validate model.facebook "facebook" 
            && Social.validate model.twitter "twitter"
            && Social.validate model.github "github" then
                ({ model | warning = [] }, patch model model.user.token)
            else
                ({ model | warning = "Invalid social network link" :: [] }, Cmd.none)

view: Model -> Html Msg
view model =
    let
        user = model.user
    in
    div [][ 
        h3 [] [ text "Update your bio" ]
        , div [ class "help-block" ] [ text "Update the description others see on your profile"]
        , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div[][
                textarea [ cols 100
                , rows 10
                , id "bio"
                , style "resize" "vertical"
                , Html.Attributes.value model.bio
                , onInput Bio ] []
            ]
        ] 
        , hr [] []
        , h3 [] [ text "Link your social accounts" ]
        , div [ class "help-block" ] [ text "Share your social accounts with our users!" ]
        , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "fb" ] [ text "Link your Facebook:" ]
                    , input [ id "fb"
                    , type_ "text"
                    , class "form-control"
                    , Html.Attributes.value model.facebook
                    , onInput Facebook ] []
                ]
            ]
        ]
        , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "tw" ] [ text "Link your Twitter:" ]
                    , input [ id "tw"
                    , type_ "text"
                    , class "form-control"
                    , Html.Attributes.value model.twitter
                    , onInput Twitter ] []
                ]
            ]
        ]
        , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ][ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "git" ] [ text "Link your Github:" ]
                    , input [ id "git"
                    , type_ "text"
                    , class "form-control"
                    , Html.Attributes.value model.github
                    , onInput Github ] []
                ]
            ]
        ]
        , hr [] []
        , h3 [] [ text "Update" ]
        , div [ class "help-block" ] [ text "Save all changes to your basic information" ]
        , button [ class "btn btn-primary", style "margin-bottom" "10px", onClick UpdateSettings ] [ text "Update Settings" ]
        , if List.length model.warning > 0 then
            div [ class "alert alert-warning"
            , style "width" "30%"
            , style "margin" "auto"
            , style "margin-bottom" "40px" ][
                --show all warnings (only one at a time, was testing usage of List to store errors)
                div[](List.map text model.warning)
           ]
        else
            text ""
    ]

settingsEncoder: Model -> Encode.Value
settingsEncoder model =
    Encode.object 
        [   
            ("facebook", Encode.string model.facebook)
            , ("twitter", Encode.string model.twitter)
            , ("github", Encode.string model.github)
            , ("bio", Encode.string model.bio)
        ]

patch: Model -> String -> Cmd Msg
patch model token =
    --update account with newly entered information
    Http.request
    {
        method = "PATCH"
        , headers = [ Http.header "auth" token ]
        , url = Server.url ++ "/account/update"
        , body = Http.jsonBody <| settingsEncoder model
        , expect = Http.expectWhatever UpdateResponse
        , timeout = Nothing
        , tracker = Nothing
    }