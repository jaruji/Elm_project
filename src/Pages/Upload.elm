module Pages.Upload exposing (..)
import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import File exposing (File)
import File.Select as Select
import Task
import Time
import User
import Server
import Loading as Loader
import Tag

type alias Model =
  { hover: Bool
  , preview: String
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
  }


init : Maybe User.Model -> Nav.Key -> (Model, Cmd Msg)
init user key =
  (Model False "" key user "" [] 0 "" "" "" Loading "" NotLoaded, Cmd.none)

type Msg
  = Pick
  | Title String
  | Description String
  | DragEnter
  | DragLeave
  | GotFiles File
  | GetPreview String
  | Response (Result Http.Error())
  | Upload
  | RemoveImg
  | RemoveTitle
  | RemoveDesc
  | RemoveTags
  | KeyHandler Int
  | Tag String

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
    Pick -> 
      (model, Select.file ["image/*", "application/pdf"] GotFiles)

    Title title ->
      ({ model | title = title }, Cmd.none)

    Description desc ->
      ({ model | description = desc }, Cmd.none)

    DragEnter ->
      ({ model | hover = True }, Cmd.none)

    DragLeave ->
      ({ model | hover = False }, Cmd.none)

    GotFiles file ->
      ( 
        { model | hover = False, fileSize = File.size file, mime = File.mime file, fileStatus = Loaded file }
        , Cmd.batch [ Task.perform GetPreview <| File.toUrl file ] --, put file ]
      )

    GetPreview url ->
      ({ model | preview = url }, Cmd.none)

    Upload ->
      if model.title == "" then
        ({ model | warning = "You need to choose a title for your image" }, Cmd.none)
      else
        case model.fileStatus of
          Loaded img ->
            case model.user of
              Just user ->
                ({ model | warning = "Loading" }, put model img user.token)
              Nothing ->
                (model, Cmd.none)
          _ ->
            ({ model | warning = "Choose an image to upload" }, Cmd.none)

    Response response ->
      case response of
        Ok string ->
          ( model, Nav.reload )
        Err log ->
          ({ model | warning = "Connection error, please try again later" }, Cmd.none)

    KeyHandler keyCode ->
      case keyCode of
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

    RemoveTitle ->
      ({ model | title = "" }, Cmd.none)

    RemoveDesc ->
      ({ model | description = "" }, Cmd.none)

    RemoveTags ->
      ({ model | tags = [] }, Cmd.none)



-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW

view : Model -> Html Msg
view model =
  case model.user of
    Just _ ->
      div[ style "text-align" "center" ][
        h1 [] [ text "Upload your image" ]
        , div [ class "help-block" ] [ text "Fill out the following form to upload your image" ]
        , div [ class "panel panel-default", style "width" "60%", style "margin" "20px auto" ][
          div [ class "panel-heading" ] [
            cancelButton RemoveTitle "28"
            , input [ id "title"
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
             div [ 
              style "border" (if model.hover then "1px solid lightgreen" else "1px solid #ccc")
              , class "panel-body"
              , style "padding" "60px"
              , hijackOn "dragenter" (Decode.succeed DragEnter)
              , hijackOn "dragover" (Decode.succeed DragEnter)
              , hijackOn "dragleave" (Decode.succeed DragLeave)
              --, hijackOn "drop" dropDecoder
            ][ 
              button [ class "btn btn-primary", onClick Pick ] [ text "Select image" ]
              , div [ class "help-block" ] [ text "-OR-" ]
              , div [ class "help-block" ] [ text "Drag & Drop" ]
              
            ]
          else
            div [ class "panel-body" ] [
              cancelButton RemoveImg "35"  
              , viewPreview model.mime model.preview
              --, button [ class "cancel" ] [ span [ class "sr-only"] [ ] ]
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
          "" ->
            text ""
          "Loading" ->
            div [ class "alert alert-info"
            , style "width" "50%"
            , style "margin" "auto"
            , style "margin-bottom" "20px" ][
              Loader.render Loader.Circle Loader.defaultConfig Loader.On
              , text model.warning 
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
      div [] [ 
        a [ href "/sign_in" ] [ text "Sign In" ]
        , text " to upload images"
        , div [] [ text "Don't have an account yet? "
                 , a [ href "/sign_up" ] [ text "Sign Up" ] ]
      ]


viewPreview: String -> String -> Html msg
viewPreview mime url =
  div []
    [ 
      case mime of
        "application/pdf" ->
          embed[ 
          --option to upload .pdf files too
          src url
          , style "type" "application/pdf"
          , style "scrollbar" "0"
          , style "width" "100%"
          , style "margin" "auto"
          , style "display" "block"
          --, style "max-height" "50000px"
          ][]
        _ ->
          img [ src url
          , style "text-align" "center" 
          , style "display" "block" 
          , style "width" "100%"
          --, style "height" "100%" 
          , style "margin" "auto" ] []
    ]

getSizeInKb: Int -> String
getSizeInKb b =
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


keyPress: (Int -> msg) -> Attribute msg
keyPress tagger =
  on "keydown" (Decode.map tagger keyCode)

hijackOn: String -> Decode.Decoder msg -> Attribute msg
hijackOn event decoder =
  preventDefaultOn event (Decode.map hijack decoder)


hijack: msg -> (msg, Bool)
hijack msg =
  (msg, True)

put: Model -> File -> String -> Cmd Msg
put model file token = 
  Http.request
    { method = "PUT"
    , headers = [ 
      Http.header "name" (File.name file)
      , Http.header "auth" token 
      , Http.header "description" model.description
      , Http.header "tags" (Debug.toString model.tags)
      , Http.header "title" model.title
      ]
    , url = Server.url ++ "/upload/image"
    , body = Http.fileBody file
    , expect = Http.expectWhatever Response
    , timeout = Nothing
    , tracker = Nothing
    }