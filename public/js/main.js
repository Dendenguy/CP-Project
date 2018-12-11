const trains = []
const vertices = {}
const edges = []

function findNextId(list) {
    for (let id = 1; id < 1000; id++) {
        let found = false
        for (let element of list) {
            if (element.id == id) {
                found = true
                break
            }
        }
        if(!found)
            return id
    }
}

function addTrainHandler() {
    const releaseTime = parseInt($("#releaseTime").val())
    const dueTime = parseInt($("#dueTime").val())
    const fromStation = $("#fromStation").val().toLowerCase()
    const toStation = $("#toStation").val().toLowerCase()
    if (typeof(releaseTime) == "number" && releaseTime >= 0 && typeof(dueTime) == "number" && dueTime >= 0 && typeof(fromStation) == "string" && !parseInt(fromStation) && !parseInt(toStation) && typeof(toStation) == "string" && fromStation !== toStation) {
        if (vertices[toStation] && vertices[fromStation]) {
            addTrain(releaseTime, dueTime, fromStation, toStation)
        } else {
            showAlert("Please add edges involving the entered train stations/vertices first.")
        }
    } else {
        showAlert("Invalid train information entered. Please fill out all the train fields correctly.")
    }
}

function addTrain(releaseTime, dueTime, fromStation, toStation) {
    const id = findNextId(trains)
    addTrainRow(id, releaseTime, dueTime, fromStation, toStation)
    trains.push({id: id, releaseTime: releaseTime, dueTime: dueTime, from: fromStation, to: toStation}) 
}

function addTrainRow(id, releaseTime, dueTime, fromStation, toStation) {
    $("#trains tr").eq(id-1).before(
        `<tr id="train-${id}" class="d-flex">
            <td class="col-1">${id}</td>
            <td class="col-2">${releaseTime}</td>
            <td class="col-2">${dueTime}</td>
            <td class="col-2">${fromStation}</td>
            <td class="col-2">${toStation}</td>
            <td class="col-3"><button type="button" class="btn btn-danger" onclick="removeTrain(${id})">X</button></td>
        </tr>`
    )
}

function removeTrain(id) {
    for (let i = 0; i < trains.length; i++) {
        let train = trains[i]
        if (train.id == id) {
            trains.splice(i, 1)
            break;
        }
    }
    $(`#train-${id}`).remove()
}

function addEdgeHandler() {
    const fromVertex = $("#fromVertex").val().toLowerCase()
    const toVertex = $("#toVertex").val().toLowerCase()
    const length = parseInt($("#edgeLength").val())
    const type = $("#edgeType").val() == "Single"?1:2
    if (fromVertex && toVertex && length && type) {
        addEdge(fromVertex, toVertex, length, type)
    } else {
        showAlert("Invalid edge information entered. Please fill out all the edge fields correctly.")
    }
}

function addEdge(fromVertex, toVertex, length, type) {
    const id = findNextId(edges)
    edges.push({id: id, from: fromVertex, to: toVertex, length: length, type: type})
    addEdgeRow(id, fromVertex, toVertex, length, type)
    vertices[fromVertex] = vertices[fromVertex]?vertices[fromVertex]++:1
    vertices[toVertex] = vertices[toVertex]?vertices[toVertex]++:1
}

function addEdgeRow(id, from, to, length, type) {
    $("#edges tr").eq(id-1).before(
    `<tr id='edge-${id}' class="d-flex">
        <td class="col-1">${id}</td>
        <td class="col-2">${from}</td>
        <td class="col-2">${to}</td>
        <td class="col-2">${length}</td>
        <td class="col-2">${type}</td>
        <td class="col-3"><button type="button" class="btn btn-danger" onclick="removeEdge(${id})">X</button></td>
    </tr>`
    )
}

function removeEdge(id) {
    for (let i = 0; i < edges.length; i++) {
        let edge = edges[i]
        if (edge.id == id) {
            edges.splice(i, 1)
            decrementVertex(edge.from)
            decrementVertex(edge.to)
            break;
        }
    }
    $(`#edge-${id}`).remove()
}

function clearEdges() {
    for (let i = edges.length-1; i >= 0; i--) {
        removeEdge(edges[i].id)
    }
}

function decrementVertex(vertex) {
    vertices[vertex]--
    if (vertices[vertex] <= 0) {
        delete vertices[vertex]
        removeTrainsWithVertex(vertex)
    }
}

function removeTrainsWithVertex(vertex) {
    for (let i = trains.length-1; i >= 0; i--) {
        let train = trains[i]
        if (train.from == vertex || train.to == vertex) {
            removeTrain(train.id)
        }
    }
}

function clearTrains() {
    for (let i = trains.length-1; i >= 0; i--) {
        removeTrain(trains[i].id)
    }
}


function populateSchedule(response) {
    const tablePane = $("#tablePane")
    tablePane.empty()
    const schedule = response.schedule
    const tardiness = response.tardiness
    for (let i = 0; i < schedule.length; i++) {
        let trainRoute = schedule[i]
        const element = $(`
        <div class="row h-100 align-items-center">
            <div class="col-1">
                <h6>Train ${i+1}:</h6>
            </div>
            <div class="col-8">
                <table class="table">
                    <thead>
                        <tr id="routeHead-${i}" class="d-flex"></tr>
                    </thead>
                    <tbody>
                        <tr id="routeRow-${i}" class="d-flex"></tr>
                    </tbody>
                </table>
            </div>
        </div>`)
        
        tablePane.append(element)
        
        const routeHead = $(`#tablePane #routeHead-${i}`)
        const routeRow = $(`#tablePane #routeRow-${i}`)
        for (let j = 0; j < trainRoute.length; j++) {
            let stop = trainRoute[j]
            let previousArrivalTime = j > 1?trainRoute[j-1].arrivalTime:stop.departureTime
            let toolTipText = `Arrived at ${stop.from} at: <b>${previousArrivalTime}m</b><br>`
            if (stop.departureTime - previousArrivalTime > 0)
                toolTipText += `Waited at ${stop.from} for: <b>${stop.departureTime - previousArrivalTime}m</b><br>`
            toolTipText += `Departed from ${stop.from} at: <b>${stop.departureTime}m</b>`
            routeHead.append(`<th class='col-2'>${stop.from}</th>`)
            routeRow.append(`<td class='col-2' data-toggle="tooltip" data-placement="top" title="${toolTipText}">${stop.departureTime}</td>`)
            if (j == trainRoute.length-1) {
                routeHead.append(`<th class='col-3'>${stop.to}</th>`)
                routeRow.append(`<td class='col-3'>${stop.arrivalTime} - Finished</td>`)
            }
        }
              
    }
    tablePane.append(`<div class='row h-100 align-items-center'><h6 class='col-6'>Total Tardiness: ${tardiness} minutes</h6></div>`)
    $('#tablePane [data-toggle="tooltip"]').tooltip({html: true})  
}

function schedule() {
    if (edges.length > 0 && trains.length > 0) {
        $("#scheduleButton").html("<i class='fa fa-circle-o-notch fa-spin'></i> Scheduling").attr("disabled", "disabled");
        vertexNames = Object.getOwnPropertyNames(vertices)
        $.ajax({
            url: "schedule/",
            method: "POST",
            data: JSON.stringify({edges: edges, trains: trains, vertices: vertexNames}),
            contentType: "application/json; charset=utf-8",
            dataType: "json",
            timeout: 0
        }).done(function(response) {
            if (response.success) {
                populateSchedule(response.result)
                $('#scheduleModal').modal({})
            } else {
                console.log(response.error)
                showAlert(response.error)
            }
        }).fail(function(response) {
            if (response.statusText == "error") {
                showAlert("Request to API timed out.")
            } else
                showAlert("Unexpected Error: " + response.statusText)
            console.log(response)
        }).always(() => {
            $("#scheduleButton").removeAttr("disabled").html("Schedule")
        })
    } else {
        showAlert("Please add edges and trains above before scheduling")
    }
}

function showAlert(message) {
    $("#errorMessage").html(message)
    $("#errorModal").modal('show')
}

const exampleTrains = [
    [0, 240, 'f', 'a'],
    [60, 270, 'i', 'a'],
    [30, 210, 'i', 'm'],
    [60, 300, 'm', 'a'],
    [180, 360, 'a', 'j'],
    [120, 330, 'a', 'f'],
    [90, 240, 'c', 'm'],
    [30, 210, 'h', 'f'],
    [60, 300, 'm', 'g'],
    [90, 300, 'm', 'd'],
    [150, 300, 'f', 'i']
]

const exampleEdges = [
    ['a', 'b', 40, 1],
    ['b', 'c', 40, 2],
    ['c', 'k', 60, 1],
    ['c', 'd', 50, 1],
    ['d', 'e', 35, 1],
    ['e', 'f', 35, 1],
    ['d', 'g', 30, 1],
    ['g', 'h', 30, 1],
    ['h', 'i', 25, 1],
    ['h', 'j', 30, 2],
    ['j', 'l', 60, 2],
    ['m', 'l', 20, 1],
    ['l', 'k', 60, 1]
]

function loadExample() {
    clearEdges()
    clearTrains()
    for (let edge of exampleEdges) {
        addEdge(edge[0], edge[1], edge[2], edge[3])
    }
    for (let train of exampleTrains) {
        addTrain(train[0], train[1], train[2], train[3])
    }
}

$(function () {
    $('[data-toggle="tooltip"]').tooltip()
})
