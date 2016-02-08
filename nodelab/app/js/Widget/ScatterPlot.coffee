BaseWidget   = require ('Widget/BaseWidget')
vs           = require('shaders/sdf.vert')()
DOMURL       = window.URL || window.webkitURL || window;

loader = new THREE.TextureLoader();

shouldRender = require('app').shouldRender

class Group extends BaseWidget
  constructor: (widgetId, width, height) ->
    super widgetId, width, height

    @texture = new THREE.Texture()

    @createPlotMesh()

  createPlotMesh: ->
    plotMesh = new THREE.PlaneBufferGeometry(1, 1)
    plotMesh.applyMatrix new THREE.Matrix4().makeTranslation(0.5, 0.5, 0.0)


    @plotUniforms =
      size:      { type: 'v2', value: new THREE.Vector2(@width, @height) }
      objectId:  { type: 'v3', value: new THREE.Vector3(0, 0, 0) }
      map:       { type: 't',  value: @texture }

    @plotUniforms[k] = v for k, v of $$.commonUniforms

    @plot = new THREE.Mesh plotMesh, new THREE.ShaderMaterial
      uniforms:       @plotUniforms
      vertexShader:   vs
      fragmentShader: require('shaders/plot.frag')()
      transparent:    true
      blending:       THREE.NormalBlending
      side:           THREE.DoubleSide
      derivatives:    true

    @plot.scale.x = @width
    @plot.scale.y = @height
    # @plot.rotation.x = Math.PI

    @mesh.add @plot


  setData: (vector) ->
    @data = vector
    @renderData()

  renderData: ->
    cf = $$.commonUniforms.camFactor.value

    svg = d3.select("body")
      .append("svg")
      .attr("xmlns", "http://www.w3.org/2000/svg")
      .attr("width", @width)
      .attr("height", @height)
      .attr('fill', "#ffffff");

    data = @data

    myChart = new dimple.chart(svg, data)
    myChart.addCategoryAxis("x", "Index");
    myChart.addMeasureAxis("y", "Value");

    myChart.addSeries(null, dimple.plot.bubble);
    myChart.defaultColors = [
          new dimple.color("#3498db", "#2980b9", 1), # blue
          new dimple.color("#e74c3c", "#c0392b", 1), # red
          new dimple.color("#2ecc71", "#27ae60", 1), # green
          new dimple.color("#9b59b6", "#8e44ad", 1), # purple
          new dimple.color("#e67e22", "#d35400", 1), # orange
          new dimple.color("#f1c40f", "#f39c12", 1), # yellow
          new dimple.color("#1abc9c", "#16a085", 1), # turquoise
          new dimple.color("#95a5a6", "#7f8c8d", 1)  # gray
    ]

    myChart.draw();

    texWidth  = Math.pow(2, Math.ceil(Math.log2(cf * @width)))
    texHeight = Math.pow(2, Math.ceil(Math.log2(cf * @height)))

    texWidth2  = Math.pow(2, Math.ceil(Math.log2(@width)))
    texHeight2 = Math.pow(2, Math.ceil(Math.log2(@height)))

    overWidth =  texWidth  / @width
    overHeight = texHeight / @height


    svg.attr("width",  texWidth)
       .attr("height", texHeight);
    svg.select("g").attr("transform", "scale(" + cf + ")")

    svgCode = new Blob([svg[0][0].outerHTML], {
        type: 'image/svg+xml;charset=utf-8'
    });
    url = DOMURL.createObjectURL(svgCode);
    loader.load url, (tex) =>
      @plotUniforms.map.value = tex
      @plotUniforms.map.value.needsUpdate = true
      @plot.position.y = texHeight / cf
      @plot.scale.set texWidth / cf, -texHeight / cf , 1.0
      shouldRender()
      DOMURL.revokeObjectURL url


  relayout: ->
    @renderData()
  redrawTextures: -> @renderData()

module.exports = Group;