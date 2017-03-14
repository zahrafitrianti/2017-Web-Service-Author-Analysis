module Update exposing (update, initialState)

import Http
import Bootstrap.Navbar as Navbar
import Types exposing (..)


initialState : ( Model, Cmd Msg )
initialState =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg

        defaultAuthorRecognition =
            { knownAuthorMode = PasteText
            , knownAuthorText = ""
            , unknownAuthorMode = PasteText
            , unknownAuthorText = ""
            , result = Nothing
            , language = EN
            }

        defaultAuthorProfiling =
            { profilingMode = PasteText
            , profilingText = fillerText1
            , result = Just { gender = "Male", age = 20 }
            }
    in
        ( { route = AuthorRecognition
          , navbarState = navbarState
          , profiling = defaultAuthorProfiling
          , attribution = defaultAuthorRecognition
          }
        , navbarCmd
        )


toggleInputMode : InputMode -> InputMode
toggleInputMode mode =
    case mode of
        FileUpload ->
            PasteText

        PasteText ->
            FileUpload


{-| How our model should change when a message comes in
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )

        NavbarMsg state ->
            ( { model | navbarState = state }, Cmd.none )

        ChangeRoute newRoute ->
            ( { model | route = newRoute }, Cmd.none )

        AttributionMsg msg ->
            -- performs a nested update on the attribution
            let
                ( newAttribution, attributionCommands ) =
                    updateAttribution msg model.attribution
            in
                ( { model | attribution = newAttribution }
                , Cmd.map AttributionMsg attributionCommands
                )

        ProfilingMsg msg ->
            -- performs a nested update on the attribution
            let
                ( newProfiling, profilingCommands ) =
                    updateProfiling msg model.profiling
            in
                ( { model | profiling = newProfiling }
                , Cmd.map ProfilingMsg profilingCommands
                )


updateProfiling : ProfilingMessage -> ProfilingState -> ( ProfilingState, Cmd ProfilingMessage )
updateProfiling msg profiling =
    case msg of
        ToggleProfilingInputMode ->
            ( { profiling | profilingMode = toggleInputMode profiling.profilingMode }
            , Cmd.none
            )

        SetProfilingText newText ->
            ( { profiling | profilingText = newText }
            , Cmd.none
            )

        UploadAuthorProfiling ->
            ( profiling, Cmd.none )


updateAttribution : AttributionMessage -> AttributionState -> ( AttributionState, Cmd AttributionMessage )
updateAttribution msg attribution =
    case msg of
        PerformAttribution ->
            ( attribution, performAttribution attribution )

        ServerResponse response ->
            case response of
                Err error ->
                    ( attribution, Cmd.none )

                Ok fromServer ->
                    ( { attribution | result = Just fromServer }
                    , Cmd.none
                    )

        ToggleInputMode KnownAuthor ->
            ( { attribution | knownAuthorMode = toggleInputMode attribution.knownAuthorMode }
            , Cmd.none
            )

        ToggleInputMode UnknownAuthor ->
            ( { attribution | unknownAuthorMode = toggleInputMode attribution.unknownAuthorMode }
            , Cmd.none
            )

        SetText KnownAuthor newText ->
            ( { attribution | knownAuthorText = newText }
            , Cmd.none
            )

        SetText UnknownAuthor newText ->
            ( { attribution | unknownAuthorText = newText }
            , Cmd.none
            )

        SetLanguage newLanguage ->
            ( { attribution | language = newLanguage }
            , Cmd.none
            )


performAttribution : AttributionState -> Cmd AttributionMessage
performAttribution attribution =
    let
        toServer =
            { knownAuthorText = attribution.knownAuthorText, unknownAuthorText = attribution.unknownAuthorText }

        body =
            Http.jsonBody (encodeToServer toServer)
    in
        Http.post (webserverUrl ++ authorRecognitionEndpoint) body decodeFromServer
            |> Http.send ServerResponse


webserverUrl : String
webserverUrl =
    "http://localhost:8080"


authorRecognitionEndpoint : String
authorRecognitionEndpoint =
    "/api/attribution"


fillerText1 =
    """Leverage agile frameworks to provide a robust synopsis for high level overviews. Iterative approaches to corporate strategy foster collaborative thinking to further the overall value proposition. Organically grow the holistic world view of disruptive innovation via workplace diversity and empowerment.
"""


fillerText2 =
    """This is the update of Unknown Author.
"""