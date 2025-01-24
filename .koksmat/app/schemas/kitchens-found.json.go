package schemas

type KitchensFound []struct {
	Description string      `json:"description"`
	Name        string      `json:"name"`
	Path        string      `json:"path"`
	Readme      string      `json:"readme"`
	Stations    interface{} `json:"stations"`
	Tag         string      `json:"tag"`
	Title       string      `json:"title"`
}
