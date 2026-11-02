.pragma library

var initialized = false
var enabled = true
var instances = []

function registerInstance(inst, defaultEnabled) {
  if (!initialized) {
    enabled = !!defaultEnabled
    initialized = true
  }
  if (instances.indexOf(inst) === -1) {
    instances.push(inst)
  }
  return enabled
}

function unregisterInstance(inst) {
  var idx = instances.indexOf(inst)
  if (idx !== -1) {
    instances.splice(idx, 1)
  }
}

function isPrimary(inst) {
  return instances.length === 0 || instances[0] === inst
}

function setEnabled(nextState, initiator) {
  enabled = !!nextState
  var snapshot = instances.slice()
  for (var i = 0; i < snapshot.length; i++) {
    var item = snapshot[i]
    if (item && typeof item.applyOsdEnabledState === "function") {
      item.applyOsdEnabledState(enabled, item === initiator || isPrimary(item))
    }
  }
}
