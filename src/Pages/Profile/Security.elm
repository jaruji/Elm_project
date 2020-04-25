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
--implement password change DONE
--finish email verif and fix the server side error NOT YET
--implement account delete - deletes all your images and comments too! DONE

type alias Model =
  {
    user: User.Model
    , key: Nav.Key
    , code: String
    , password: String
    , newPassword: String
    , passStatus: Status
    , delStatus: Status
    , mailStatus: Status
    , codeStatus: Status
  }

init: Nav.Key -> User.Model -> (Model, Cmd Msg)
init key user =
    (Model user key "" "" "" Loading None Loading Loading, Cmd.none)

type Msg
  = Empty
  | Request
  | Code String
  | Password String
  | NewPassword String
  | ChangePassword
  | PasswordResponse (Result Http.Error())
  | Verify
  | VerifyResponse (Result Http.Error Bool)
  | MailResponse (Result Http.Error())
  | Delete
  | ConfirmDelete
  | DeleteResponse (Result Http.Error())

type Status
  = Loading
  | Success
  | Failure
  | None

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
                            ({ model | codeStatus = Success }, Nav.reload) 
                        False ->
                            ({ model | codeStatus = Failure }, Cmd.none)
                Err log ->
                    ({ model | codeStatus = Failure }, Cmd.none)

        MailResponse response ->
            case response of
                Ok _ ->
                    ({ model | mailStatus = Success }, Cmd.none)
                Err _ ->
                    ({ model | mailStatus = Failure }, Cmd.none)

        Code string ->
            ({ model | code = string }, Cmd.none)

        Password string ->
            ({ model | password = string }, Cmd.none)

        NewPassword string ->
            ({ model | newPassword = string }, Cmd.none)

        Delete ->
            ({ model | delStatus = Loading }, Cmd.none)

        ConfirmDelete ->
            (model, deleteAccount model)

        ChangePassword ->
            (model, changePassword model)

        PasswordResponse response ->
            case response of
                Ok _ ->
                    ({ model | passStatus = Success }, Cmd.batch [ User.logout, Nav.reload, Nav.pushUrl model.key "/sign_in" ] )
                Err _ ->
                    ({ model | passStatus = Failure }, Cmd.none)

        DeleteResponse response ->
            case response of
                Ok _ ->
                    ({ model | delStatus = Success }, Cmd.batch [ User.logout, Nav.reload, Nav.pushUrl model.key "/" ])
                Err _ ->
                    ({ model | delStatus = Failure }, Cmd.none)

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
            ] 
            , button [ class "btn btn-primary"
            , style "margin-bottom" "10px"
            , style "margin-top" "20px"
            , if model.user.verif == False then
                disabled True
              else
                style "" ""
            , onClick ChangePassword ][
                text "Change Password" 
            ]
            , case model.passStatus of
                Failure ->
                    div[ class "alert alert-warning"
                    , style "width" "50%"
                    , style "margin" "auto" ][
                        text "Password change failed"
                    ]
                Success ->
                    div[ class "alert alert-success"
                    , style "width" "50%"
                    , style "margin" "auto" ][
                        text "Password successfully changed"
                    ]
                _ ->
                    text ""
            , hr [] []
            , h3 [] [ text "Delete my account" ]
            , div [ class "help-block" ][ 
                text "Press the following button if you wish to permanently delete your account. This will also delete your posts and comments!"
            ]
            , case model.delStatus of
                None ->
                    button [ class "btn btn-danger"
                    , style "margin-bottom" "15px"
                    , onClick Delete ][
                        text "Delete account" 
                    ]
                Loading ->
                    div[ class "alert alert-danger form-group row"
                    , style "width" "50%"
                    , style "margin" "auto" ][
                        div [ class "col-md-offset-2 col-md-8" ] [
                            div[ class "form-group has-feedback" ][
                                label [ for "del" ] [ text "Enter your password:" ]
                                , input [ id "del", type_ "password", class "form-control", Html.Attributes.value model.password, onInput Password ] []
                            ]
                            , button [ class "btn btn-danger"
                            , onClick ConfirmDelete ][ text "Confirm" ]
                        ]
                    ]
                Failure ->
                    div[ class "alert alert-warning"
                    , style "width" "50%"
                    , style "margin" "auto" ][
                        text "Deleting account failed"
                    ]
                Success ->
                    text ""
        ]   

viewVerify: Model -> Html Msg
viewVerify model =
  div [ class "form-horizontal fade in alert alert-info", id "form", style "margin" "auto", style "width" "75%" ] [
    h2 [ class "text-center" ] [ text "Verify your e-mail address" ]
    , div [ class "help-block" ] [ text ("Your account is not verified. We will send a verification mail to " ++ model.user.email) ]
    , button [ class "btn btn-primary", style "margin-bottom" "10px", onClick Request ] [ text "Send me the code" ]
    , case model.mailStatus of
        Failure ->
            div [ class "alert alert-warning"
            , style "width" "30%"
            , style "margin" "auto" ][
                text "Connection error"
            ]
        Success ->
            div [ class "alert alert-success"
            , style "width" "30%"
            , style "margin" "auto" ][
                text "Mail successfully sent"
            ]
        _ ->
            text ""
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ][
          div[][ 
                div[ class "form-group" ][
                  label [ for "verify" ] [ text "Enter the received code:" ]
                  , input [ id "verify", type_ "code", class "form-control", Html.Attributes.value model.code, onInput Code ] []
                  , button [ class "btn btn-primary", style "margin-top" "10px", onClick Verify ][ text "Verify" ]
                ]
                , case model.codeStatus of
                    Failure ->
                        div [ class "alert alert-warning"
                        , style "width" "30%"
                        , style "margin" "auto" ][
                            text "Invalid code"
                        ]
                    _ ->
                        text ""
          ]
        ]
    ]
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

deleteEncoder: String -> Encode.Value
deleteEncoder password =
    Encode.object[("password", Encode.string (Crypto.sha256 password))]

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

deleteAccount: Model -> Cmd Msg
deleteAccount model =
    Http.request
    { method = "DELETE"
    , headers = [ Http.header "auth" model.user.token ]
    , url = Server.url ++ "/account/delete"
    , body = Http.jsonBody <| deleteEncoder model.password
    , expect = Http.expectWhatever DeleteResponse
    , timeout = Nothing
    , tracker = Nothing
    }

requestMail: String -> Cmd Msg
requestMail email = 
    Http.get {
      url = Server.url ++ "/mailer/send" ++ "?mail=" ++ email
      , expect = Http.expectWhatever MailResponse
    }

verifyCode: Model -> Cmd Msg
verifyCode model =
    Http.request {
        method = "GET"
        , headers = [ Http.header "auth" model.user.token ]
        , url = Server.url ++ "/account/verify" ++ "?username=" 
                ++ model.user.username ++ "&code=" ++ model.code
        , body = Http.emptyBody
        , expect = Http.expectJson VerifyResponse (field "response" Decode.bool)
        , timeout = Nothing
        , tracker = Nothing
    }