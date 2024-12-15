export const navStack = new NavPathStack()


export const navEvents: Map<string, (namesJoin: string) => void> = new Map()

export function navNamesJoin(): string {
  return navStack.getAllPathName().join(":")
}

navStack.setInterception({
  willShow() {
    const namesJoin = navNamesJoin();
    navEvents.forEach((v) => {
      try {
        v(namesJoin)
      } catch (e) {
        console.error(e)
      }
    })
  }
})