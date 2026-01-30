```mermaid
flowchart TD
    Start([Script starts:<br/>oraenv.sh or oraup.sh])
    
    Start --> LoadInterface[Load plugin_interface.sh<br/>Define core interface functions]
    
    LoadInterface --> Discovery[Plugin Discovery Phase]
    Discovery --> ScanDir[Scan src/lib/plugins/ directory]
    ScanDir --> FilterFiles{Filter<br/>*_plugin.sh}
    FilterFiles -->|Skip| SkipInterface[Skip plugin_interface.sh]
    FilterFiles -->|Found| ListPlugins[Found plugins:<br/>• database_plugin.sh<br/>• datasafe_plugin.sh<br/>• client_plugin.sh<br/>• iclient_plugin.sh<br/>• oud_plugin.sh<br/>• java_plugin.sh]
    
    SkipInterface --> ValidationPhase
    ListPlugins --> ValidationPhase[Validation Phase]
    
    ValidationPhase --> LoopPlugins{For each<br/>plugin file}
    LoopPlugins -->|Yes| CheckExists{File<br/>exists AND<br/>readable?}
    CheckExists -->|No| NextPlugin
    CheckExists -->|Yes| CheckShebang{Proper<br/>shebang?}
    CheckShebang -->|No| NextPlugin
    CheckShebang -->|Yes| LoadingPhase
    
    LoadingPhase[Loading Phase] --> SourcePlugin[source plugin_file.sh]
    SourcePlugin --> SetMetadata[Set plugin metadata:<br/>• plugin_name<br/>• plugin_version<br/>• plugin_description]
    
    SetMetadata --> DefineFunc[Define Interface Functions]

    DefineFunc --> Func1[plugin_detect_installation<br/>Auto-discover installations]
    DefineFunc --> Func2[plugin_validate_home<br/>Validate ORACLE_HOME/BASE_HOME]
    DefineFunc --> Func3[plugin_adjust_environment<br/>Align ORACLE_HOME to layout]
    DefineFunc --> Func4[plugin_build_base_path<br/>Resolve ORACLE_BASE_HOME]
    DefineFunc --> Func5[plugin_build_env<br/>Build env vars per product/instance]
    DefineFunc --> Func6[plugin_check_status<br/>Check instance/service state]
    DefineFunc --> Func7[plugin_get_metadata<br/>Version/edition metadata]
    DefineFunc --> Func8[plugin_discover_instances<br/>Discover instances/domains]
    DefineFunc --> Func9[plugin_get_instance_list<br/>Enumerate instances/domains]
    DefineFunc --> Func10[plugin_supports_aliases<br/>SID-like aliases?]
    DefineFunc --> Func11[plugin_build_bin_path<br/>PATH components]
    DefineFunc --> Func12[plugin_build_lib_path<br/>LD_LIBRARY_PATH components]
    DefineFunc --> Func13[plugin_get_config_section<br/>Config section name]
    DefineFunc --> Func14[plugin_should_show_listener (category)<br/>Listener visible?]
    DefineFunc --> Func15[plugin_check_listener_status (category)<br/>Listener status]

    Func1 --> NextPlugin
    Func2 --> NextPlugin
    Func3 --> NextPlugin
    Func4 --> NextPlugin
    Func5 --> NextPlugin
    Func6 --> NextPlugin
    Func7 --> NextPlugin
    Func8 --> NextPlugin
    Func9 --> NextPlugin
    Func10 --> NextPlugin
    Func11 --> NextPlugin
    Func12 --> NextPlugin
    Func13 --> NextPlugin
    Func14 --> NextPlugin
    Func15 --> NextPlugin[Next plugin]
    
    NextPlugin --> LoopPlugins
    LoopPlugins -->|No| UsagePhase
    
    UsagePhase[Usage Phase] --> CallerScript{Calling<br/>script?}
    
    CallerScript -->|oraenv.sh| OraenvUse[oraenv Integration]
    OraenvUse --> DetectType[Detect product type<br/>from Oracle Home path]
    DetectType --> TypeCheck{Type<br/>detected?}
    TypeCheck -->|Yes| LoadProductPlugin[Load product-specific plugin]
    TypeCheck -->|No| UseDefault[Use default behavior]
    LoadProductPlugin --> ValidateHome[Call plugin_validate_home]
    ValidateHome --> AdjustEnv[Call plugin_adjust_environment<br/>Adjust ORACLE_HOME if needed]
    AdjustEnv --> SetupEnv[Setup Oracle environment:<br/>ORACLE_HOME, PATH,<br/>LD_LIBRARY_PATH, etc.]
    UseDefault --> SetupEnv
    SetupEnv --> EnvComplete
    
    CallerScript -->|oraup.sh| OraupUse[oraup Integration]
    OraupUse --> GetRegistry[Get installations<br/>from Registry API]
    GetRegistry --> LoopHomes{For each<br/>installation}
    LoopHomes -->|Yes| ExtractType[Extract type field<br/>from registry object]
    ExtractType --> FindPlugin{Plugin<br/>for type<br/>loaded?}
    FindPlugin -->|No| DefaultStatus[status = available]
    FindPlugin -->|Yes| CallCheckStatus[Call plugin_check_status<br/>Get actual running status]
    CallCheckStatus --> DisplayStatus[Display in formatted output:<br/>TYPE : NAME STATUS HOME]
    DefaultStatus --> DisplayStatus
    DisplayStatus --> NextHome[Next home]
    NextHome --> LoopHomes
    LoopHomes -->|No| EnvComplete
    
    EnvComplete([Plugin system ready])
    
    style Start fill:#e1f5ff,stroke:#01579b,stroke-width:3px
    style LoadInterface fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    
    style Discovery fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style ScanDir fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    style ListPlugins fill:#e1bee7,stroke:#6a1b9a,stroke-width:2px
    
    style ValidationPhase fill:#c5cae9,stroke:#3949ab,stroke-width:2px
    style CheckExists fill:#c5cae9,stroke:#3949ab,stroke-width:2px
    style CheckShebang fill:#c5cae9,stroke:#3949ab,stroke-width:2px
    
    style LoadingPhase fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style SourcePlugin fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    style SetMetadata fill:#b3e5fc,stroke:#01579b,stroke-width:2px
    
    style Func1 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func2 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func3 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func4 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func5 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func6 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func7 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Func8 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Func9 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Func10 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func11 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func12 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func13 fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    style Func14 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    style Func15 fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    
    style UsagePhase fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style OraenvUse fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    style OraupUse fill:#ffccbc,stroke:#bf360c,stroke-width:2px
    
    style EnvComplete fill:#c8e6c9,stroke:#2e7d32,stroke-width:3px
```
