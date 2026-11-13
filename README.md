# Notaria-Aventureros
Estructura ideal:
```text
res://
├── Scenes/
│   ├── Core/
│   │   ├── GameManager.tscn         # Autoload: Persistencia, Día (1-5), Dinero, Honor (-100 a 100), Baúl
│   │   ├── AudioManager.tscn        # Autoload: Buses Master/BGM/SFX, filtro Low-Pass y SFX de honor
│   │   └── SceneTransition.tscn    # Autoload (CanvasLayer): Fades a negro entre pantallas
│   │
│   ├── Menus/
│   │   ├── MainMenu.tscn            # Pantalla de título: Jugar, Opciones, Créditos, Salir
│   │   ├── OptionsMenu.tscn         # Ajustes: Volumen Master/BGM/SFX, Pantalla Completa (Reutilizable)
│   │   ├── PauseMenu.tscn           # Popup in-game (ESC): Reanudar, Opciones, Reiniciar Día, Salir al Menú
│   │   └── CreditsMenu.tscn         # Créditos del equipo y menciones reglamentarias de la jam
│   │
│   ├── Flow/
│   │   ├── Day_Intro.tscn           # Pantalla de inicio de jornada: "Día X: Decreto Real matutino"
│   │   ├── Day_Summary.tscn         # Resumen nocturno: Balances, soborno del gato, notas familiares
│   │   └── Endings_Screen.tscn      # Evaluación final: Epílogos para los 4 Finales y Game Over
│   │
│   └── Desk/
│       ├── Desk_View.tscn           # Escena raíz del gameplay diario (integra los sub-módulos)
│       ├── Counter_Window.tscn      # Marco exterior, aventurero actual y guardia gato
│       ├── Inspection_Area.tscn     # Bandeja física donde se aloja el botín actual
│       ├── Tool_Lens.tscn           # Lente arrastrable con dial de 3 filtros de shader
│       ├── Universal_Form.tscn      # Formulario fijo con los 3 OptionButtons (coartada)
│       ├── Rulebook_Popup.tscn      # Manual de leyes a pantalla completa
│       ├── Action_Panel.tscn        # Botones de trámite: Cobrar, Arrestar, Confiscar y Robar
│       └── Honor_Vignette.tscn      # CanvasLayer overlay: Destello blanco/rojo periférico
│
├── Scripts/
│   ├── Core/
│   │   ├── game_manager.gd          # Máquina de estados global, economía y honor
│   │   ├── audio_manager.gd         # Manejo dinámico de música, SFX y audio buses
│   │   └── scene_transition.gd      # Control de animación de fundidos y change_scene_to_file
│   ├── Menus/
│   │   ├── main_menu.gd             # Navegación del menú principal
│   │   ├── options_menu.gd          # Control de sliders de audio (AudioServer) y display
│   │   └── pause_menu.gd            # get_tree().paused y gestión de inputs de escape
│   ├── Flow/
│   │   ├── day_intro.gd             # Muestra decreto del día y avanza a Desk_View
│   │   ├── day_summary.gd           # Cálculo nocturno, lógica de sobornos y avance
│   │   └── endings_screen.gd        # Carga el texto e ilustración del final correspondiente
│   ├── Desk/
│   │   ├── desk_view.gd             # Orquestador del turno: coordina cliente, bandeja y acciones
│   │   ├── tool_lens.gd             # Lógica de arrastre y conmutación de shaders
│   │   ├── universal_form.gd        # Lectura y reseteo de los 3 desplegables
│   │   └── action_panel.gd          # Emisión de señales de resolución (Cobrar/Arrestar/Confiscar/Robar)
│   └── Data/
│       ├── ItemsDatabase.gd         # Diccionario de los 40-50 objetos y sus propiedades ocultas
│       └── DailyRulesDatabase.gd    # Leyes y prohibiciones específicas para cada día (1 a 5)
│
├── Shaders/
│   ├── lens_mask.gdshader           # Máscara circular para El Lente
│   ├── spectrum_magic.gdshader      # Revelación de runas arcanas
│   ├── spectrum_bio.gdshader        # Revelación de toxinas y esporas
│   ├── spectrum_xray.gdshader       # Revelación de hojas ocultas y mecanismos
│   └── honor_vignette.gdshader      # Viñeta periférica blanca/roja
│
└── Assets/
    ├── Art/                         # Sprites PNG, texturas de UI y fuentes pixel
    └── Audio/                       # Pistas BGM (.ogg) y efectos SFX (.wav)
```