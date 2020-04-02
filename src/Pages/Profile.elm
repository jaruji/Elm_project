module Pages.Profile exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import User
import Session
import Server
import File exposing (File, size, name)
import File.Select as Select
import Json.Decode as Decode exposing (Decoder, field, string, int)
import Json.Encode as Encode exposing (..)
import LineChart
import FeatherIcons as Icons
import Social

type alias Model =
  {  
    user: User.Model
    , key: Nav.Key
    , tab: Tab
    , code: String
    , bio: String
  }

type alias Point =
  { 
    x : Float
    , y : Float 
  }

type Msg
-- Switch msg are used for switching tabs
  = SwitchInformation
  | SwitchSettings
  | SwitchSecurity
  | SwitchHistory
-- Here are msgs needed for updating and handling all inputs
  | Bio String
  --| OldPassword String
  --| NewPassword String
  --| NewPasswordA String
--submit update
  | UpdateSettings
  | Request
  | Code String
  | Verify
  | MailResponse (Result Http.Error())
  | AvatarResponse (Result Http.Error String)
  | VerifyResponse (Result Http.Error Bool)
  | Select
  | GotFile File

type Tab
  = Information
  | Settings
  | Security
  | History

init: Nav.Key -> User.Model -> ( Model, Cmd Msg, Session.UpdateSession)
init key user = 
  (Model user key Information "" "", Cmd.none, Session.NoUpdate)

update: Msg -> Model -> ( Model, Cmd Msg, Session.UpdateSession )
update msg model =
  case msg of
    SwitchInformation ->
        ({model | tab = Information}, Cmd.none, Session.NoUpdate)
    SwitchSettings ->
        ({model | tab = Settings}, Cmd.none, Session.NoUpdate)
    SwitchSecurity ->
        ({model | tab = Security}, Cmd.none, Session.NoUpdate)
    SwitchHistory ->
        ({model | tab = History}, Cmd.none, Session.NoUpdate)
    Request ->
        (model, requestMail model.user.email, Session.NoUpdate)
    Select ->
        (model, Select.file ["image/*"] GotFile, Session.NoUpdate)
    GotFile file ->
        let
            username = model.user.username
        in
            (model, put file username, Session.NoUpdate)
    Verify -> 
        (model, verifyCode model, Session.NoUpdate)
    VerifyResponse response ->
        case response of
            Ok bool ->
                case bool of
                    True ->
                        ({model | user = verifyUser model.user}, Cmd.none, Session.Update (verifyUser model.user)) 
                    False ->
                        (model, Cmd.none, Session.NoUpdate)
            Err log ->
                (model, Cmd.none, Session.NoUpdate)

    AvatarResponse response ->
        case response of
            Ok string ->
                (model, Nav.reload, Session.NoUpdate)
            Err log ->
                (model, Cmd.none, Session.NoUpdate)

    MailResponse _ ->
        (model, Cmd.none, Session.NoUpdate)

    Code string ->
        ({model | code = string}, Cmd.none, Session.NoUpdate)

    Bio string ->
        ({model | bio = string}, Cmd.none, Session.NoUpdate)

    UpdateSettings ->
        (model, patch model.user.token "bio" model.bio, Session.NoUpdate)

verifyUser: User.Model -> User.Model
verifyUser user =
    { user | verif = True }

updateAvatar: String -> User.Model -> User.Model
updateAvatar avatar user =
    { user | avatar = avatar }
    

view: Model -> Html Msg
view model =
  let 
    user = model.user
  in 
    div[][
        div[ class "jumbotron" ][
            img [ class "avatar", style "border" "10px solid white", src user.avatar, style "border-radius" "50%", height 200, width 200, onClick Select ] []
            , br [] []
            , h3 [] [ text user.username
                    , if user.verif == True then 
                        span [ class "glyphicon glyphicon-ok-circle", style "color" "green", style "margin-left" "5px" ][]
                    else
                        span [ class "glyphicon glyphicon-remove-circle", style "color" "red", style "margin-left" "5px" ] []
            ]
            , div [ style "margin-bottom" "20px" ] [
                ul [ class "nav" ] [
                    case user.facebook of
                        Just url ->
                            Social.viewFacebook url
                        Nothing ->
                            div [][]
                    , case user.twitter of
                        Just url ->
                            Social.viewTwitter url
                        Nothing ->
                            div[][]
                    , case user.github of
                        Just url ->
                            Social.viewGithub url
                        Nothing ->
                            div [][]
                ]
            ]
            , div [ style "font-style" "italic" ] [ text user.bio ]
            , ul [ class "nav nav-pills" ][
                li [][ a [ if model.tab == Information then style "text-decoration" "underline" else style "" "", style "color" "black", href "#information", onClick SwitchInformation ] [ {--span [ class " glyphicon glyphicon-info-sign" ][],--} text "Information"] ]
                , li [][ a [ if model.tab == Settings then style "text-decoration" "underline" else style "" "", style "color" "black", href "#settings", onClick SwitchSettings ] [ text "Settings"] ]
                , li [][ a [ if model.tab == Security then style "text-decoration" "underline" else style "" "", style "color" "black", href "#security", onClick SwitchSecurity ] [ text "Security"] ]
                , li [][ a [ if model.tab == History then style "text-decoration" "underline" else style "" "", style "color" "black", href "#history", onClick SwitchHistory ] [ text "History"] ]
            ]
        ]
        , case model.tab of
            Information ->
                div[ class "list-group" ][
                    h3 [] [ text "Basic information" ]
                    , div [ class "help-block" ] [ text ("Here are some basic information about " ++ user.username) ]
                    , viewStringInfo user.firstName "First Name"
                    , viewStringInfo user.surname "Last Name"
                    , viewStringInfo user.occupation "Occupation"
                    , hr [] []
                    , h3 [] [ text "Account information" ]
                    , div [ class "help-block" ] [ text ("Here are some information about " ++ user.username ++ "'s account") ]
                    , viewStringInfo user.firstName "Registered at"
                ]
            Settings ->
                div [][ 
                    h3 [] [ text "Want to change your avatar?" ]
                    , div [ class "help-block" ] [ text "Upload a picture from your computer and make it your avatar! You can also click on your avatar!" ]
                    , button [ class "btn btn-primary", style "margin-bottom" "10px", onClick Select ] [ text "Select file" ]
                    , hr [] []
                    , h3 [] [ text "Update your bio" ]
                    , div [ class "help-block" ] [ text "Update the description others see on your profile"]
                    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                        div[][
                            textarea [ cols 100, rows 10, id "bio", placeholder user.bio, Html.Attributes.value model.bio, onInput Bio ] []
                        ]
                    ] 
                    , hr [] []
                    , h3 [] [ text "Tell us more about yourself" ]  
                    , div [ class "help-block" ] [ text "Fill out the following information to complete your profile" ]  
                    , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                        div [ class "col-md-offset-2 col-md-8" ] [
                            div[ class "form-group has-feedback" ][
                                label [ for "name" ] [ text "First Name:" ]
                                , input [ id "name", type_ "text", class "form-control" ] []
                            ]
                        ]
                    ]
                    , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                        div [ class "col-md-offset-2 col-md-8" ] [
                            div[ class "form-group has-feedback" ][
                                label [ for "lastname" ] [ text "Last Name:" ]
                                , input [ id "lastname", type_ "text", class "form-control" ] []
                            ]
                        ]
                    ]
                    ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                        div [ class "col-md-offset-2 col-md-8" ] [
                            div[ class "form-group has-feedback" ][
                                label [ for "occ" ] [ text "Occupation:" ]
                                , input [ id "occ", type_ "text", class "form-control" ] []
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
                                , input [ id "fb", type_ "text", class "form-control" ] []
                            ]
                        ]
                    ]
                    ,div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                        div [ class "col-md-offset-2 col-md-8" ] [
                            div[ class "form-group has-feedback" ][
                                label [ for "tw" ] [ text "Link your Twitter:" ]
                                , input [ id "tw", type_ "text", class "form-control" ] []
                            ]
                        ]
                    ]
                    , div [ class "form-group row", style "width" "30%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                        div [ class "col-md-offset-2 col-md-8" ] [
                            div[ class "form-group has-feedback" ][
                                label [ for "git" ] [ text "Link your Github:" ]
                                , input [ id "git", type_ "text", class "form-control" ] []
                            ]
                        ]
                    ]
                    , hr [] []
                    , h3 [] [ text "Update" ]
                    , div [ class "help-block" ] [ text "Save all changes to your basic information" ]
                    , button [ class "btn btn-primary", style "margin-bottom" "10px" ] [ text "Update Settings" ]
                    , hr [] []
                    , h3 [] [ text "Delete my account" ]
                    , div [ class "help-block" ] [ text "Press the following button if you wish to permanently delete your account"]
                    , button [ class "btn btn-danger", style "margin-bottom" "50px" ] [ text "Delete account" ]
                ]
            Security ->
                div[][
                    h3 [] [ text "Verify your account" ]
                    , div [ class "help-block" ] [ text "Verification is required for the completion of certain tasks"]
                    , case user.verif of
                        False ->
                            div[][
                                viewVerify model
                                , hr [] []
                            ]
                        _ -> 
                            div[ class "alert alert-success", style "width" "20%", style "margin" "auto" ][ text "Your account is verified" ]
                    , hr [] []
                    , h3 [] [ text "Enable two-factor authentication?" ]
                    , div [ class "help-block" ] [ text "Make your account more secure by enabling two-factor verification" ]
                    , case user.verif of
                        True ->
                            button [ class "btn btn-success", style "margin-bottom" "15px", style "margin-top" "20px" ] [ text "Enable" ]                    
                        False ->
                            div [] [
                                button [ class "btn btn-success", style "margin-bottom" "15px", style "margin-top" "20px", disabled True ] [ text "Enable" ]
                                , div [ class "alert alert-warning", style "width" "20%", style "margin" "auto" ] [ text "You must verify your e-mail address first!" ]
                            ]
                    , hr [] []
                    , h3 [] [ text "Want to change your password?" ]
                    , div [ class "help-block" ] [ text "Change your password by filling out the following form" ]
                    , div [ class "form-inline" ][
                        div [ class "form-group row", style "padding-bottom" "15px" ] [ 
                            div [ class "col-md-offset-2 col-md-8" ] [
                                div[ class "form-group has-feedback" ][
                                    label [ for "old" ] [ text "Old Password:" ]
                                    , input [ id "old", type_ "password", class "form-control" ] []
                                ]
                            ]
                        ]
                        , div [ class "form-group row", style "padding-bottom" "15px" ] [ 
                            div [ class "col-md-offset-2 col-md-8" ] [
                                div[ class "form-group has-feedback" ][
                                    label [ for "new" ] [ text "New Password:" ]
                                    , input [ id "new", type_ "password", class "form-control" ] []
                                ]
                            ]
                        ]
                        , div [ class "form-group row", style "padding-bottom" "15px" ] [ 
                            div [ class "col-md-offset-2 col-md-8" ] [
                                div[ class "form-group has-feedback" ][
                                    label [ for "newA" ] [ text "New Password Again:" ]
                                    , input [ id "newA", type_ "password", class "form-control" ] []
                                ]
                            ]
                        ]
                    ] 
                    , button [ class "btn btn-primary", style "margin-bottom" "100px", style "margin-top" "20px" ] [ text "Change Password" ]
                ]
            History ->
                div[ class "container", style "text-align" "center" ][ 
                    h3 [] [ text "Activity in the last month" ] 
                    , div [ class "help-block" ] [ text "This graph represents your image upload activity in the last month" ]
                    , div [ style "margin-left" "20%"] [ LineChart.view1 .x .y
                        [ Point 1 2, Point 5 5, Point 10 10 ] ]
                    , hr [] []
                    , h3 [] [ text "My posts" ] 
                    , div [ class "help-block" ] [ text "This sections contains your entire post history" ]
                ]
    ]

viewStringInfo: Maybe String -> String -> Html Msg
viewStringInfo attr name = 
    let 
        key = name ++ ": "
    in
        case attr of
            Just value ->
                div [ class "form-group row", style "width" "40%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
                    div [ class "col-md-offset-2 col-md-8" ] [
                        div[ class "form-group has-feedback" ][
                            label [ for name ] [ text key ]
                            , input [ id name, type_ "text", style "text-align" "center", readonly True, class "form-control", placeholder value ] []
                        ]
                    ]
                ]
            Nothing ->
                div [][]

viewVerify: Model -> Html Msg
viewVerify model =
  div [ class "form-horizontal fade in alert alert-info", id "form", style "margin" "auto", style "width" "75%" ] [
    h2 [ class "text-center" ] [ text "Verify your e-mail address" ]
    , div [ class "help-block" ] [ text ("Your account is not verified. We will send a verification mail to " ++ model.user.email) ]
    , button [ class "btn btn-primary", style "margin-bottom" "10px", onClick Request ] [ text "Send me the code" ]
    , div [ class "form-group row", style "width" "50%", style "margin" "auto", style "padding-bottom" "15px" ] [ 
        div [ class "col-md-offset-2 col-md-8" ] [
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

emailEncoder: String -> Encode.Value
emailEncoder email =
  Encode.object
  [ ( "email", Encode.string email )
  ]

codeEncoder: Model -> Encode.Value
codeEncoder model =
    Encode.object
    [
        ("verifCode", Encode.string model.code )
        , ( "username", Encode.string model.user.username)
    ]

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

stringEncoder: String -> String -> Encode.Value
stringEncoder key value =
    Encode.object [(key, Encode.string value)]

put : File -> String -> Cmd Msg
put file user = 
  Http.request
    { method = "PUT"
    , headers = [ Http.header "name" (File.name file), Http.header "user" user ]
    , url = Server.url ++ "/upload/profile"
    , body = Http.fileBody file 
    , expect = Http.expectJson AvatarResponse ( field "response" Decode.string )
    , timeout = Nothing
    , tracker = Nothing
    }

patch : String -> String -> String -> Cmd Msg
patch token key value =
    Http.request
    {
        method = "PATCH"
        , headers = [ Http.header "auth" token ]
        , url = Server.url ++ "/account/update"
        , body = Http.jsonBody <| (stringEncoder key value)
        , expect = Http.expectWhatever MailResponse
        , timeout = Nothing
        , tracker = Nothing
    }
