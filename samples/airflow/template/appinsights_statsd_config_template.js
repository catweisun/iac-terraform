{
    backends: ["./backends/appinsights"],  // [Required] The Application Insighst StatsD backend
    aiInstrumentationKey: "${appinsights_key}",  // [Required] Your instrumentation key
    aiPrefix: "osdu_airflow",  // [Optional] Send only metrics with this prefix
    aiRoleName: "airflow",  // [Optional] Add this role name context tag to every metric
    aiRoleInstance: "${airflow_instance_name}",  // [Optional] Add this role instance context tag to every metric
    aiTrackStatsDMetrics: true,  // [Optional] Send StatsD internal metrics to Application Insights
    log: {
        backend: "stdout",    // where to log: stdout or syslog [string, default: stdout]
        level: ""       // log level for [node-]syslog [string, default: LOG_INFO]
    },
    debug: false
}