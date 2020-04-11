module Pages.Profile.Settings exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import User
import Server
import Http
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Json.Encode as Encode exposing (..)

type alias Model =
  {
    user: User.Model
    , bio: String
    , firstName : String
    , surname: String
    , occupation: String
    , facebook: String
    , twitter: String
    , github: String
  }

init: User.Model -> (Model, Cmd Msg)
init user =
    (Model user "" "" "" "" "" "" "", Cmd.none)

type Msg
  = Empty
  | Bio String
  | FirstName String
  | Surname String
  | Occupation String
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

        FirstName string ->
            ({model | firstName = string}, Cmd.none)

        Surname string -> 
            ({model | surname = string}, Cmd.none)

        Occupation string ->
            ({model | occupation = string}, Cmd.none)

        Facebook string ->
            ({model | facebook = string}, Cmd.none)

        Twitter string ->
            ({model | twitter = string}, Cmd.none)

        Github string ->
            ({model | github = string}, Cmd.none)
        UpdateSettings ->
            if model.bio == "" || model.firstName == "" || model.surname == "" 
            || model.occupation == "" || model.facebook == "" || model.twitter == "" 
            || model.github == "" then
                (model, Cmd.none)
            else
                (model, patch model model.user.token)

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
        , h3 [] [ text "Tell us more about yourself" ]  
        , div [ class "help-block" ] [ text "Fill out the following information to complete your profile" ]  
        , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "name" ] [ text "First Name:" ]
                    , input [ id "name", type_ "text", class "form-control", Html.Attributes.value model.firstName, onInput FirstName ] []
                ]
            ]
        ]
        , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "lastname" ] [ text "Last Name:" ]
                    , input [ id "lastname", type_ "text", class "form-control", Html.Attributes.value model.surname, onInput Surname ] []
                ]
            ]
        ]
        ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "occ" ] [ text "Occupation:" ]
                    , input [ id "occ", type_ "text", class "form-control", Html.Attributes.value model.occupation, onInput Occupation ] []
                ]
            ]
        ]
        ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "mail" ] [ text "E-mail:" ]
                    , input [ id "mail", disabled True, type_ "email", class "form-control", Html.Attributes.value user.email ] []
                ]
            ]
        ]
        , hr [] []
        , h3 [] [ text "Link your social accounts" ]
        , div [ class "help-block" ] [ text "Share your social accounts with our users!" ]
        , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "fb" ] [ text "Link your Facebook:" ]
                    , input [ id "fb", type_ "text", class "form-control", Html.Attributes.value model.facebook, onInput Facebook ] []
                ]
            ]
        ]
        ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "tw" ] [ text "Link your Twitter:" ]
                    , input [ id "tw", type_ "text", class "form-control", Html.Attributes.value model.twitter, onInput Twitter ] []
                ]
            ]
        ]
        , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
            div [ class "col-md-offset-2 col-md-8" ] [
                div[ class "form-group has-feedback" ][
                    label [ for "git" ] [ text "Link your Github:" ]
                    , input [ id "git", type_ "text", class "form-control", Html.Attributes.value model.github, onInput Github ] []
                ]
            ]
        ]
        , hr [] []
        , h3 [] [ text "Update" ]
        , div [ class "help-block" ] [ text "Save all changes to your basic information" ]
        , button [ class "btn btn-primary", style "margin-bottom" "50px", onClick UpdateSettings ] [ text "Update Settings" ]
    ]

settingsEncoder: Model -> Encode.Value
settingsEncoder model =
    Encode.object 
        [
            ("firstName", Encode.string model.firstName)
            , ("surname", Encode.string model.surname)
            , ("occupation", Encode.string model.occupation)
            , ("facebook", Encode.string model.facebook)
            , ("twitter", Encode.string model.twitter)
            , ("github", Encode.string model.github)
            , ("bio", Encode.string model.bio)
        ]

patch: Model -> String -> Cmd Msg
patch model token =
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