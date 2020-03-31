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
import User
import Server
import Loading as Loader

type alias Model =
  { hover: Bool
  , preview: String
  , key: Nav.Key
  , user: Maybe User.Model
  , tags: List String
  , fileSize: Int
  , title: String
  , description: String
  , status: Status
  , warning: String
  , fileStatus: FileStatus
  }


init : Maybe User.Model -> Nav.Key -> (Model, Cmd Msg)
init user key =
  (Model False "" key user [] 0 "" "" Loading "" NotLoaded, Cmd.none)

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
      (model, Select.file ["image/*"] GotFiles)

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
        { model | hover = False, fileSize = File.size file, fileStatus = Loaded file }
        , Cmd.batch [ Task.perform GetPreview <| File.toUrl file ] --, put file ]
      )

    GetPreview url ->
      ({ model | preview = url }, Cmd.none)

    Upload ->
      if model.title == "" then
        ({ model | warning = "You need to choose a title" }, Cmd.none)
      else
        case model.fileStatus of
          Loaded img ->
            ({ model | warning = "Loading" }, put img)
          _ ->
            ({ model | warning = "Choose an image to upload" }, Cmd.none)

    Response response ->
      case response of
        Ok string ->
          ( model, Nav.reload )
        Err log ->
          ({ model | warning = "Server error" }, Cmd.none)



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
        , div [ class "panel panel-default", style "width" "50%", style "margin" "20px auto"  ][
          div [ class "panel-heading" ] [
            --h2 [ class "panel-title" ] [
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
              --, style "text-align" "center"
              ] []
            --]
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
              , div [ class "help-block" ] [ text "Drag and Drop an image here" ]
              
            ]
          else
            div [ class "panel-body" ] [ 
              viewPreview model.preview 
              --, button [ class "cancel" ] [ span [ class "sr-only"] [ ] ]
          ]
          , div [ class "panel-footer", style "height" "100px" ][
            textarea [ 
            id "bio"
            , placeholder "Enter image description here..."
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
          , div [ class "panel-footer"] [ text "Add tags here..." ]
        ]
        , div [ class "help-block" ][
          text ("Loaded file size: " ++ (String.fromInt model.fileSize) ++ " B")
        ]
        , button [ class "btn btn-primary", onClick Upload, style "margin-bottom" "10px" ] [ text "Upload" ] 
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


viewPreview : String -> Html msg
viewPreview url =
  div []
    [ 
      img [ src url
      , style "text-align" "center" 
      , style "display" "block" 
      , style "width" "100%"
      , style "height" "100%" 
      --, style "width" ""
      , style "margin" "auto" ] []
    ]

hijackOn : String -> Decode.Decoder msg -> Attribute msg
hijackOn event decoder =
  preventDefaultOn event (Decode.map hijack decoder)


hijack : msg -> (msg, Bool)
hijack msg =
  (msg, True)

put : File -> Cmd Msg
put file = 
  Http.request
    { method = "PUT"
    , headers = [ Http.header "name" (File.name file) ]
    , url = Server.url ++ "/upload/image"
    , body = Http.fileBody file
    , expect = Http.expectWhatever Response
    , timeout = Nothing
    , tracker = Nothing
    }