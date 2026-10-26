:- use_module(library(http/http_server)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).

% Base de datos dinámica para registrar las inscripciones de los estudiantes
:- dynamic inscrito/2. % formato: inscrito(EstudianteID, Actividad)

%Hechos

% actividad(Nombre, Categoria, Habilidad, Enfoque)
actividad('Orquesta Sinfonica del IPN', musica, musical, academico_clasico).
actividad('Banda de Marcha del IPN', musica, musical, aire_libre_ritmo).
actividad('Coro del IPN', musica, vocal, interpretacion_vocal).
actividad('Taller de Guitarra Acustica', musica, instrumental, hobby_expresion).
actividad('Taller de Piano Clasico', musica, instrumental, academico_clasico).
actividad('Compañia de Danza Contemporanea', danza, corporal, expresion_artistica).
actividad('Ballet Folklorico del IPN', danza, corporal, tradicion_ritmo).
actividad('Taller de Salsa y Bachata', danza, corporal, recreativo_social).
actividad('Taller de Danza Urbana y Hip Hop', danza, corporal, recreativo_social).
actividad('Grupo Representativo de Teatro', teatro, escenica, drama_actuacion).
actividad('Taller de Improv y Stand-up', teatro, escenica, creatividad_humor).
actividad('Taller de Pantomima y Circo', teatro, escenica, expresion_artistica).
actividad('Taller de Fotografia Digital', artes_visuales, visual, tecnica_audiovisual).
actividad('Taller de Pintura y Dibujo', artes_visuales, manual, artes_plasticas).
actividad('Taller de Escultura y Modelado', artes_visuales, manual, artes_plasticas).
actividad('Club de Literatura y Escritura Creativa', literatura, intelectual, lectura_redaccion).
actividad('Taller de Cine debate y Apreciacion', literatura, intelectual, tecnica_audiovisual).

% representativo(Actividad)
representativo('Orquesta Sinfonica del IPN').
representativo('Banda de Marcha del IPN').
representativo('Coro del IPN').
representativo('Compañia de Danza Contemporanea').
representativo('Ballet Folklorico del IPN').
representativo('Grupo Representativo de Teatro').

% rendimiento_academico(EstudianteID, Estatus)
rendimiento_academico('2026630001', regular).
rendimiento_academico('2026630002', regular).
rendimiento_academico('2026630003', irregular).

%Reglas

afinidad_exacta(perfil(Cat, Hab, Enf), Actividad) :-
    actividad(Actividad, Cat, Hab, Enf).

afinidad_por_enfoque(perfil(_, _, Enf, Actividad) :-
    actividad(Actividad, _, _, Enf).

afinidad_por_habilidad(perfil(_, Hab, _), Actividad) :-
    actividad(Actividad, _, Hab, _).

grupo_oficial(Actividad) :- representativo(Actividad).

elegible_beca_institucional(Boleta, Actividad) :-
    grupo_oficial(Actividad),
    rendimiento_academico(Boleta, regular).

elegible_apoyo_taller(Boleta, Actividad) :-
    actividad(Actividad, _, _, _),
    rendimiento_academico(Boleta, regular).

puede_inscribirse(Boleta, _) :-
    \+ inscrito(Boleta, _).
puede_inscribirse(Boleta, Actividad) :-
    inscrito(Boleta, ActividadActual),
    Actividad \== ActividadActual,
    !, fail.

realizar_inscripcion(EstudianteID, Actividad, Mensaje) :-
    puede_inscribirse(EstudianteID, Actividad),
    assertz(inscrito(EstudianteID, Actividad)).

obtener_recomendaciones_minimas(Perfil, Recomendaciones) :-
    findall(Act, afinidad_exacta(Perfil, Act), L1),
    findall(Act, afinidad_por_habilidad(Perfil, Act), L2),
    findall(Act, afinidad_por_enfoque(Perfil, Act), L3),
    append(L1, L2, Temp),
    append(Temp, L3, ListaBruta),
    sort(ListaBruta, Recomendaciones),
    length(Recomendaciones, Cantidad),
    Cantidad >= 3.

% ------------------------------------------------------------------------------
% 3. SERVIDOR HTTP Y API JSON PARA LA PÁGINA WEB
% ------------------------------------------------------------------------------

iniciar_servidor(Puerto) :-
    http_server(http_dispatch, [port(Puerto)]).

:- http_handler(root(api/recomendar), api_recomendar, []).
:- http_handler(root(api/inscribir), api_inscribir, []).

api_recomendar(Request) :-
    http_parameters(Request, [
        categoria(Cat, [atom]),
        habilidad(Hab, [atom]),
        interes(Int, [atom])
    ]),
    Perfil = perfil(Cat, Hab, Int),
    (   obtener_recomendaciones_minimas(Perfil, ListaActividades)
    ->  maplist(formatear_actividad_json, ListaActividades, JsonActividades),
        reply_json(json([status(ok), recomendaciones(JsonActividades)]))
    ;   reply_json(json([status(error), mensaje('No se reunieron al menos 3 recomendaciones para este perfil.')]))
    ).

formatear_actividad_json(Actividad, json([nombre(Actividad), es_representativo(EsRep)])) :-
    (es_grupo_oficial(Actividad) -> EsRep = true ; EsRep = false).

api_inscribir(Request) :-
    http_parameters(Request, [
        estudiante(EstudianteID, [atom]),
        actividad(Actividad, [atom])
    ]),
    realizar_inscripcion(EstudianteID, Actividad, Mensaje),
    reply_json(json([status(ok), mensaje(Mensaje)])).

