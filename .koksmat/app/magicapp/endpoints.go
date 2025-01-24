package magicapp

/*
func addCoreEndpoints(s *web.Service, jwtAuth func(http.Handler) http.Handler) {
	s.Method(http.MethodGet, "/blob/{tag}", nethttp.NewHandler(getBlob()))

	//s.Use(rateLimitByAppId(50))
	s.MethodFunc(http.MethodPost, "/api/v1/subscription/notify", validateSubscription)
	s.Route("/v1/webhooks", func(r chi.Router) {
		r.Group(func(r chi.Router) {
			//r.Use(adminAuth, nethttp.HTTPBasicSecurityMiddleware(s.OpenAPICollector, "User", "User access"))
			r.Use(jwtAuth, nethttp.HTTPBearerSecurityMiddleware(s.OpenAPICollector, "Bearer", "", ""))
			r.Use(rateLimitByAppId(50))
			r.Method(http.MethodGet, "/", nethttp.NewHandler(getWebHooks()))

		})
	})
	s.Mount("/debug/core", middleware.Profiler())
}

func addAdminEndpoints(s *web.Service, jwtAuth func(http.Handler) http.Handler) {
	s.Route("/v1/admin", func(r chi.Router) {
		r.Group(func(r chi.Router) {
			r.Use(jwtAuth, nethttp.HTTPBearerSecurityMiddleware(s.OpenAPICollector, "Bearer", "", ""))
			r.Use(rateLimitByAppId(50))
			r.Method(http.MethodGet, "/auditlogsummary", nethttp.NewHandler(GetAuditLogSummarys()))
			r.Method(http.MethodGet, "/auditlogs/date/{date}/{hour}", nethttp.NewHandler(getAuditLogs()))
			r.Method(http.MethodGet, "/auditlogs/powershell/{objectId}", nethttp.NewHandler(getAuditLogPowershell()))
			r.Method(http.MethodPost, "/sharepoint/copylibrary", nethttp.NewHandler(copyLibrary()))
			r.Method(http.MethodPost, "/sharepoint/copypage", nethttp.NewHandler(copyPage()))
			r.Method(http.MethodPost, "/sharepoint/renamelibrary", nethttp.NewHandler(renameLibrary()))
			r.Method(http.MethodGet, "/user/", nethttp.NewHandler(getUsers()))
			r.Method(http.MethodPost, "/user/", nethttp.NewHandler(addUser()))
			r.Method(http.MethodPatch, "/user/{upn}/credentials", nethttp.NewHandler(updateUserCredentials()))
			r.MethodFunc(http.MethodPost, "/powershell", executePowerShell)

		})
	})

	s.Mount("/debug/admin", middleware.Profiler())
}
*/
