module Pages.Profile.Security exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Browser.Navigation as Nav
import User
import Server
import Loading as Loader exposing (LoaderType(..), defaultConfig, render)
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Decode.Extra as DecodeExtra
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import Json.Encode as Encode exposing (..)
import Http
import Browser.Navigation as Nav
import Crypto.Hash as Crypto

--TODO
--implement password change
--finish email verif and fix the server side error
--implement account delete - deletes all your images and comments too!
--or alternatively changes user to anonymous, but delete is easier

type alias Model =
  {
    user: User.Model
    , key: Nav.Key
    , code: String
    , password: String
    , newPassword: String
    , newPasswordAgain: String
    , passStatus: PasswordStatus
  }

init: Nav.Key -> User.Model -> (Model, Cmd Msg)
init key user =
    (Model user key "" "" "" "" LoadingP, Cmd.none)

type Msg
  = Empty
  | Request
  | Code String
  | Password String
  | NewPassword String
  | NewPasswordAgain String
  | ChangePassword
  | PasswordResponse (Result Http.Error())
  | Verify
  | VerifyResponse (Result Http.Error Bool)
  | MailResponse (Result Http.Error())
  | Delete

type PasswordStatus
  = LoadingP
  | SuccessP
  | FailureP

{--
type DeleteStatus
  = None
  | Loading
  | Failure
  | Success
--}

getModel: (Model, Cmd Msg) -> Model
getModel (model, cmd) =
    model

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        Empty ->
            (model, Cmd.none)

        Request ->
            (model, requestMail model.user.email)

        Verify -> 
            (model, verifyCode model)

        VerifyResponse response ->
            case response of
                Ok bool ->
                    case bool of
                        True ->
                            (model, Nav.reload) 
                        False ->
                            (model, Cmd.none)
                Err log ->
                    (model, Cmd.none)

        MailResponse _ ->
            (model, Cmd.none)

        Code string ->
            ({ model | code = string }, Cmd.none)

        Password string ->
            ({ model | password = string }, Cmd.none)

        NewPassword string ->
            ({ model | newPassword = string }, Cmd.none)

        NewPasswordAgain string ->
            ({ model | newPasswordAgain = string }, Cmd.none)

        Delete ->
            (model, Cmd.none)

        ChangePassword ->
            (model, changePassword model)

        PasswordResponse response ->
            case response of
                Ok _ ->
                    ({ model | passStatus = SuccessP }, Cmd.batch [ User.logout, Nav.reload, Nav.pushUrl model.key "/sign_in" ] )
                Err _ ->
                    ({ model | passStatus = FailureP }, Cmd.none)

view: Model -> Html Msg
view model =
    let 
        user = model.user
    in
        div[][
            h3 [] [ text "Verify your account" ]
            , div [ class "help-block" ][
                text "Verification is required for the completion of certain tasks"
            ]
            , case user.verif of
                False ->
                    div[][
                        viewVerify model
                        , hr [] []
                    ]
                _ -> 
                    div[ class "alert alert-success"
                    , style "width" "20%"
                    , style "margin" "auto" ][
                        text "Your account is verified" 
                    ]
            , hr [] []
            , h3 [] [ text "Enable two-factor authentication?" ]
            , div [ class "help-block" ][
                text "Make your account more secure by enabling two-factor verification"
            ]
            , case user.verif of
                True ->
                    button [ class "btn btn-success"
                    , style "margin-bottom" "15px"
                    , style "margin-top" "20px" ][
                        text "Enable" 
                    ]                    
                False ->
                    div [] [
                        button [ class "btn btn-success"
                        , style "margin-bottom" "15px"
                        , style "margin-top" "20px"
                        , disabled True ][ 
                            text "Enable" 
                        ]
                        , div [ class "alert alert-warning"
                        , style "width" "20%"
                        , style "margin" "auto" ][
                            text "You must verify your e-mail address first!"
                        ]
                    ]
            , hr [] []
            , h3 [] [ text "Want to change your password?" ]
            , div [ class "help-block" ][
                text "Change your password by filling out the following form." 
            ]
            , div [ class "form-inline" ][
                div [ class "form-group row"
                , style "padding-bottom" "15px" ][ 
                    div [ class "col-md-offset-2 col-md-8" ][
                        div[ class "form-group has-feedback" ][
                            label [ for "old" ] [ text "Old Password:" ]
                            , input [ id "old"
                            , type_ "password"
                            , class "form-control"
                            , Html.Attributes.value model.password
                            , onInput Password ] []
                        ]
                    ]
                ]
                , div [ class "form-group row"
                , style "padding-bottom" "15px" ] [ 
                    div [ class "col-md-offset-2 col-md-8" ] [
                        div[ class "form-group has-feedback" ][
                            label [ for "new" ] [ text "New Password:" ]
                            , input [ id "new"
                            , type_ "password"
                            , class "form-control"
                            , Html.Attributes.value model.newPassword
                            , onInput NewPassword ] []
                        ]
                    ]
                ]
                , div [ class "form-group row"
                , style "padding-bottom" "15px" ] [ 
                    div [ class "col-md-offset-2 col-md-8" ] [
                        div[ class "form-group has-feedback" ][
                            label [ for "newA" ] [ text "New Password Again:" ]
                            , input [ id "newA"
                            , type_ "password"
                            , class "form-control"
                            , Html.Attributes.value model.newPasswordAgain
                            , onInput NewPasswordAgain ] []
                        ]
                    ]
                ]
            ] 
            , button [ class "btn btn-primary"
            , style "margin-bottom" "10px"
            , style "margin-top" "20px"
            , onClick ChangePassword ][
                text "Change Password" 
            ]
            , case model.passStatus of
                LoadingP ->
                    text ""
                FailureP ->
                    div[ class "alert alert-warning"
                    , style "width" "50%"
                    , style "margin" "auto" ][
                        text "Password change failed"
                    ]
                SuccessP ->
                    div[ class "alert alert-success"
                    , style "width" "50%"
                    , style "margin" "auto" ][
                        text "Password successfully changed"
                    ]
            , hr [] []
            , h3 [] [ text "Delete my account" ]
            , div [ class "help-block" ][ 
                text "Press the following button if you wish to permanently delete your account. This will also delete your posts and comments!"
            ]
            , button [ class "btn btn-danger"
            , style "margin-bottom" "50px"
            , onClick Delete ][
                text "Delete account" 
            ]
        ]   

viewVerify: Model -> Html Msg
viewVerify model =
  div [ class "form-horizontal fade in alert alert-info", id "form", style "margin" "auto", style "width" "75%" ] [
    h2 [ class "text-center" ] [ text "Verify your e-mail address" ]
    , div [ class "help-block" ] [ text ("Your account is not verified. We will send a verification mail to " ++ model.user.email) ]
    , button [ class "btn btn-primary", style "margin-bottom" "10px", onClick Request ] [ text "Send me the code" ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ][
          div[][ 
                div[ class "form-group" ][
                  label [ for "verify" ] [ text "Enter the received code:" ]
                  , input [ id "verify", type_ "code", class "form-control", Html.Attributes.value model.code, onInput Code ] []
                  , button [ class "btn btn-primary", style "margin-top" "10px", onClick Verify ][ text "Verify" ]
                ]
          ]
        ]
    ]
  ]

codeEncoder: Model -> Encode.Value
codeEncoder model =
    Encode.object
    [
        ("verifCode", Encode.string model.code )
        , ( "username", Encode.string model.user.username)
    ]

emailEncoder: String -> Encode.Value
emailEncoder email =
  Encode.object
  [ ( "email", Encode.string email )
  ]

passwordEncoder: String -> String -> Encode.Value
passwordEncoder oldP newP =
    Encode.object [
        ("oldPassword", Encode.string (Crypto.sha256 oldP) )
        , ("newPassword", Encode.string (Crypto.sha256 newP) )
    ]

changePassword: Model -> Cmd Msg
changePassword model =
    Http.request
    { method = "PATCH"
    , headers = [ Http.header "auth" model.user.token ]
    , url = Server.url ++ "/account/password"
    , body = Http.jsonBody <| (passwordEncoder model.password model.newPassword)
    , expect = Http.expectWhatever PasswordResponse
    , timeout = Nothing
    , tracker = Nothing
    }

requestMail: String -> Cmd Msg
requestMail email = 
    Http.post {
      url = Server.url ++ "/mailer/send"
      , body = Http.jsonBody <| emailEncoder email
      , expect = Http.expectWhatever MailResponse
    }

verifyCode: Model -> Cmd Msg
verifyCode model =
    Http.post {
      url = Server.url ++ "/account/verify"
      , body = Http.jsonBody <| codeEncoder model
      , expect = Http.expectJson VerifyResponse (field "response" Decode.bool)
    }