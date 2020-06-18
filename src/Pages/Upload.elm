module Pages.Upload exposing (..)
import Browser
import Browser.Navigation as Nav
import Browser.Dom as Dom
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline as Pipeline exposing (required, optional, hardcoded)
import File exposing (File)
import File.Select as Select
import Task
import Time
import User
import Server
import Loading as Loader
import Tag
import Task exposing (..)

{--
  This page is used to upload a file with additional metada on the server,
  creating a new Post.
--}

type alias Model =
  { preview: String
  , key: Nav.Key
  , user: Maybe User.Model
  , tag: String
  , tags: List String
  , fileSize: Int
  , mime: String
  , title: String
  , description: String
  , status: Status
  , warning: String
  , fileStatus: FileStatus
  , id: String
  , fraction: Float
  }


init : Maybe User.Model -> Nav.Key -> (Model, Cmd Msg)
init user key =
  (Model "" key user "" [] 0 "" "" "" Loading "" NotLoaded "" 0.0, Task.perform (\_ -> Empty) (Dom.setViewport 0 0))

type Msg
  = Pick
  | Empty
  | Title String
  | Description String
  | GotFiles File
  | GetPreview String
  | UploadResponse (Result Http.Error String)
  | Response (Result Http.Error())
  | Upload
  | RemoveImg
  | KeyHandler Int
  | Tag String
  | Progress Http.Progress

type Status
  = Loading
  | Success String
  | Failure

type FileStatus
  = NotLoaded
  | Loaded File

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Empty ->
      (model, Cmd.none)
      
    Pick -> 
      --allow only image files to be picked
      (model, Select.file ["image/*", "application/pdf"] GotFiles)

    Title title ->
      ({ model | title = title }, Cmd.none)

    Description desc ->
      ({ model | description = desc }, Cmd.none)

    GotFiles file ->
      ( 
        --store the file uploaded to browser in a Loaded Msg, save information and get the url
        --of this file so we can display the preview
        { model | fileSize = File.size file, mime = File.mime file, fileStatus = Loaded file, fraction = 0.0 }
        , Task.perform GetPreview <| File.toUrl file
      )

    Progress progress ->
      case progress of
        Http.Sending f ->
          ({ model | fraction = Http.fractionSent f }, Cmd.none)
        Http.Receiving _ ->
          ( model, Cmd.none )

    GetPreview url ->
      --get url of image uploaded to browser
      ({ model | preview = url }, Cmd.none)

    Upload ->
      --handle all errors on frontend side (no title, no file)
      if model.title == "" then
        ({ model | warning = "You need to choose a title for your image" }, Cmd.none)
      else
        case model.fileStatus of
          Loaded img ->
            case model.user of
              Just user ->
                --start the image upload chain
                ({ model | warning = "Loading" }, put model img user.token)
              Nothing ->
                (model, Cmd.none)
          _ ->
            ({ model | warning = "Choose an image to upload" }, Cmd.none)

    UploadResponse response ->
      case response of
        Ok id ->
          case model.user of
            Just user ->
              --if upload of file was a success, we can upload it's metadata
              ({ model | id = id }, postMetatada model user.token id)
            Nothing ->
              --otherwise, there is no reason to upload metadata as the file is not saved
              --on server side (neither in fs or database)
              (model, Cmd.none)
        Err log ->
          ({ model | warning = "Connection error, please try again later" }, Cmd.none)

    Response response ->
      case response of
        Ok string ->
          --if upload was successful, we redirect user to the newly created post
          (model, Nav.pushUrl model.key ("/post/" ++ model.id))
        Err log ->
          --otherwise we notify the user that upload was not successful
          ({ model | warning = "Connection error, please try again later" }, Cmd.none)

    KeyHandler keyCode ->
      case keyCode of
        --add tag to list of tags if enter is pressed
        13 ->
          if model.tag /= "" then
            ({ model | tags = model.tag :: model.tags, tag = ""}, Cmd.none)
          else 
            (model, Cmd.none)
        _ ->
          (model, Cmd.none)

    Tag tag ->
      ({ model | tag = tag }, Cmd.none)

    RemoveImg ->
      ({ model | fileStatus = NotLoaded, fileSize = 0 }, Cmd.none)

view : Model -> Html Msg
view model =
  case model.user of
    Just _ ->
      --if user is signed in, he can upload an image and the page displays correctly
      div[ style "text-align" "center" ][
        h1 [] [ text "Upload your image" ]
        , div [ class "help-block" ] [ text "Fill out the following form to upload your image" ]
        , div [ class "panel panel-default", style "width" "60%", style "margin" "20px auto" ][
          div [ class "panel-heading" ] [
            input [ id "title"
            , type_ "text"
            , placeholder "Enter title here..."
            , style "outline" "none"
            , style "border" "none"
            , style "background" "Transparent"
            , style "margin" "auto"
            , style "width" "100%"
            , style "font-size" "20px"
            , Html.Attributes.value model.title
            , onInput Title 
            ] []
          ]
          , if model.fileSize == 0 then
              div [ class "panel-body"
              , style "padding" "60px"
              ][ 
                button [ class "btn btn-primary", onClick Pick ] [ text "Select image" ]
              ]
          else
            div [ class "panel-body" ] [
              --we "remove" the image if user presses the X button next to it
              cancelButton RemoveImg "35"  
              , viewPreview model.mime model.preview
          ]
          , div [ class "panel-footer", style "height" "100px" ][
            textarea [ 
            id "bio"
            , placeholder "Enter image description here (optional)"
            , style "height" "100%"
            , style "width" "100%"
            , style "resize" "none"
            , style "outline" "none"
            , style "border" "none"
            , style "background" "Transparent"
            , style "font-size" "15px"
            , Html.Attributes.value model.description
            , onInput Description ] []
          ]
          , div [ class "panel-footer" ] [
            input [ id "tags"
            , type_ "text"
            , placeholder "Press Enter to add tags (optional)"
            , style "outline" "none"
            , style "border" "none"
            , style "background" "Transparent"
            , style "margin" "auto"
            , style "width" "100%"
            , style "font-size" "15px"
            , Html.Attributes.value model.tag
            , onInput Tag
            , keyPress KeyHandler
            ] []
          ]
          , case List.isEmpty model.tags of
            True -> 
              div [] []
            False ->
              div [ class "panel-footer", style "text-align" "left" ] ( List.map Tag.view (List.reverse model.tags) )
        ]
        , div [ class "help-block" ][
          text ("Loaded file size: " ++ getSizeInKb model.fileSize ++ " kB")
        ]
        , button [ class "btn btn-success", onClick Upload, style "margin-bottom" "10px" ] [ text "Upload" ] 
        , case model.warning of
          --handle potential warnings
          "" ->
            text ""
          "Loading" ->
            div [ class "progress", style "width" "50%", style "margin" "auto" ][
              div [ class "progress-bar progress-bar-info"
              , style "width" (String.fromInt (round (100 * model.fraction)) ++ "%")
              , attribute "aria-valuemax" "100"
              , attribute "aria-valuemin" "0"
              , attribute "aria-valuenow" (String.fromInt (round (100 * model.fraction)))
              , attribute "role" "progressbar"
              , style "margin" "auto" ][
              ]
            ]
          _ ->
            div [ class "alert alert-warning"
            , style "width" "50%"
            , style "margin" "auto"
            , style "margin-bottom" "20px" ][ 
              text model.warning 
            ]
      ]
    Nothing ->
      --if user is not logged in, he is prompted to sign in!
      div [] [ 
        a [ href "/sign_in" ] [ text "Sign In" ]
        , text " to upload images"
        , div [] [ text "Don't have an account yet? "
                 , a [ href "/sign_up" ] [ text "Sign Up" ] ]
      ]


viewPreview: String -> String -> Html msg
viewPreview mime url =
  div []
    --display preview of image uploaded to browser
    [ 
      img [ src url
      , style "text-align" "center" 
      , style "display" "block" 
      , style "width" "100%" 
      , style "margin" "auto" ] []
    ]

getSizeInKb: Int -> String
getSizeInKb b =
  --get filesize in kB
  String.fromFloat( Basics.toFloat b / 1024.0 )

cancelButton: Msg -> String -> Html Msg
cancelButton msg offset =
  button [
  style "position" "absolute"
  , style "top" (offset ++ "%")
  , style "right" "21%"
  , style "background" "Transparent"
  , style "outline" "none"
  , style "border" "none"
  , style "color" "red"
  , style "opacity" "0.8"
  , onClick msg
  ][ span [ class "glyphicon glyphicon-remove" ] [] ]


subscriptions: Model -> Sub Msg
subscriptions model =
  Http.track "upload" Progress

keyPress: (Int -> msg) -> Attribute msg
keyPress tagger =
  --listen to key press
  on "keydown" (Decode.map tagger keyCode)

put: Model -> File -> String -> Cmd Msg
put model file token = 
  --upload a file on the server using Http.fileBody
  Http.request
    { 
      method = "PUT"
      , headers = [ 
        Http.header "name" (File.name file)
        , Http.header "auth" token
      ]
      , url = Server.url ++ "/upload/image"
      , body = Http.fileBody file
      , expect = Http.expectJson UploadResponse (Decode.field "response" Decode.string)
      , timeout = Nothing
      , tracker = Just "upload"
    }

encodeMetadata: Model -> String -> Encode.Value
encodeMetadata model id =
  Encode.object[
    ("title", Encode.string model.title)
    , ("tags", Encode.list Encode.string model.tags)
    , ("description", Encode.string model.description)
    , ("id", Encode.string id)
  ]

postMetatada: Model -> String -> String -> Cmd Msg
postMetatada model token id =
  --upload metadata to image with ID received as parameter
  Http.request
  { 
    method = "POST"
    , headers = [
      Http.header "auth" token
    ]
    , url = Server.url ++ "/upload/metadata"
    , body = Http.jsonBody <| (encodeMetadata model id)
    , expect = Http.expectWhatever Response
    , timeout = Nothing
    , tracker = Nothing
  }