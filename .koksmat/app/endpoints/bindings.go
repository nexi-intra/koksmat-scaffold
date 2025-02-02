// -------------------------------------------------------------------
// Generated by 365admin-publish
// -------------------------------------------------------------------

package endpoints

import (
	"net/http"

	chi "github.com/go-chi/chi/v5"
	"github.com/swaggest/rest/nethttp"
	"github.com/swaggest/rest/web"
)

func AddEndpoints(s *web.Service, jwtAuth func(http.Handler) http.Handler) {
	s.Route("/v1", func(r chi.Router) {
		r.Group(func(r chi.Router) {
			//r.Use(adminAuth, nethttp.HTTPBasicSecurityMiddleware(s.OpenAPICollector, "User", "User access"))
			r.Use(jwtAuth, nethttp.HTTPBearerSecurityMiddleware(s.OpenAPICollector, "Bearer", "", ""))
			//	r.Use(rateLimitByAppId(50))
			//r.Method(http.MethodPost, "/", nethttp.NewHandler(ExchangeCreateRoomsPost()))
			r.Method(http.MethodPost, "/health/ping", nethttp.NewHandler(HealthPingPost()))
			r.Method(http.MethodPost, "/health/coreversion", nethttp.NewHandler(HealthCoreversionPost()))
			r.Method(http.MethodPost, "/auth/create-app", nethttp.NewHandler(AuthCreateAppPost()))
			r.Method(http.MethodPost, "/kitchens/scan", nethttp.NewHandler(KitchensScanPost()))
			r.Method(http.MethodPost, "/kitchens/buildcache", nethttp.NewHandler(KitchensBuildcachePost()))
			r.Method(http.MethodPost, "/kitchens/publishdocusaurus", nethttp.NewHandler(KitchensPublishdocusaurusPost()))
			r.Method(http.MethodPost, "/scaffold/init", nethttp.NewHandler(ScaffoldInitPost()))
			r.Method(http.MethodPost, "/scaffold/initweb", nethttp.NewHandler(ScaffoldInitwebPost()))
			r.Method(http.MethodPost, "/scaffold/generateapi", nethttp.NewHandler(ScaffoldGenerateapiPost()))
			r.Method(http.MethodPost, "/scaffold/generateweb", nethttp.NewHandler(ScaffoldGeneratewebPost()))
			r.Method(http.MethodPost, "/scaffold/build", nethttp.NewHandler(ScaffoldBuildPost()))
			r.Method(http.MethodPost, "/scaffold/generateapp", nethttp.NewHandler(ScaffoldGenerateappPost()))

		})
	})

}
