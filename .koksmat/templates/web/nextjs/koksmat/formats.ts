export function formattedMoney(value:number, currency: string) {
    if (!value) return ""
    if (!currency) return value.toLocaleString("de-DE")
    const loc = navigator?.language ?? "de-DE"
  return value.toLocaleString(loc, { style: "currency", currency })
}

