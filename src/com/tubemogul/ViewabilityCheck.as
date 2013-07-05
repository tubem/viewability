/**
 * Copyright (c) 2013 TubeMogul
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and 
 * to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of 
 * the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
 * THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
package com.tubemogul {
import flash.external.ExternalInterface;

public class ViewabilityCheck {
	public var results:Object={};
	public var _uniqueId:String;
	public function ViewabilityCheck( uniqueId:String ) {
		_uniqueId=uniqueId;
		ExternalInterface.addCallback( uniqueId, flashProbe );
		results = checkViewability( uniqueId );
	}
	//Callback function attached to HTML Object to identify it:
	public function flashProbe( someData:* ):void {
		return;
	}


	public function checkViewability( uniqueId:String = null):Object {
		if ( uniqueId === null ) uniqueId=_uniqueId;
		var js:XML = <script><![CDATA[
				function a( obfuFn ) {
					var results = {'errCode':'e0'};

					var myObj = null;
					var objRect = null;

					var xMin = 0;
					var xMax = 0;
					var yMin = 0;
					var yMax = 0;
					var totalObjectArea = 0;

					//Find Object by looking for obfuFn (Obfuscated Function set by Flash)
					var objs = document.getElementsByTagName("object");
					for (var i = 0; i < objs.length; i++) {
						if ( !!objs[i][ obfuFn ] ) {
							myObj = objs[i];
							var rects = myObj.getClientRects();
							objRect = rects[0];

							totalObjectArea = ( objRect.right - objRect.left ) * ( objRect.bottom - objRect.top );
						}
					}

					if ( myObj == null ) {
							//report object not found
							results["error"]  = "Object not found";
							results["errCode"] = "eOB";
					} else {
							//Capture the player id for reporting (not necessary to check viewability):
							results[ 'id' ] = myObj.id;
							//Avoid including scrollbars in viewport size by taking the smallest dimensions (also
							//ensures ad object is not obscured)
							results[ 'clientWidth' ] = Infinity;
							results[ 'clientHeight' ] = Infinity;
							//document.body  - Handling case where viewport is represented by documentBody
							//.width
							if ( !isNaN( document.body.clientWidth ) && document.body.clientWidth > 0 ) {
								results[ 'clientWidth' ] = document.body.clientWidth;
							}
							//.height
							if ( !isNaN( document.body.clientHeight ) && document.body.clientHeight > 0 ) {
								results[ 'clientHeight' ] = document.body.clientHeight;
							}
							//document.documentElement - Handling case where viewport is represented by documentElement
							//.width
							if ( !!document.documentElement && !!document.documentElement.clientWidth &&
								!isNaN( document.documentElement.clientWidth ) ) {
								results[ 'clientWidth' ] = Math.min ( results[ 'clientWidth' ],
									document.documentElement.clientWidth );
							}
							//.height
							if ( !!document.documentElement && !!document.documentElement.clientHeight &&
				 				!isNaN( document.documentElement.clientHeight ) ) {
								results[ 'clientHeight' ] = Math.min ( results[ 'clientHeight' ],
									document.documentElement.clientHeight );
							}
							//window.innerWidth/Height - Handling case where viewport is represented by window.innerH/W
							//.innerWidth
							if ( !!window.innerWidth && !isNaN( window.innerWidth ) ) {
								results[ 'clientWidth' ] = Math.min ( results[ 'clientWidth' ],
									window.innerWidth );

							}
							//.innerHeight
							if ( !!window.innerHeight && !isNaN( window.innerHeight ) ) {
								results[ 'clientHeight' ] = Math.min( results[ 'clientHeight' ],
									window.innerHeight );
							}
							if ( results[ 'clientHeight' ] == Infinity || results[ 'clientWidth' ] == Infinity ) {
								results["error"] = "Failed to determine viewport";
								results["errCode"] = "eWH" ;
							} else {
								//Get player dimensions:
								results[ 'objTop' ] = objRect.top;
								results[ 'objBottom' ] = objRect.bottom;
								results[ 'objLeft' ] = objRect.left;
								results[ 'objRight' ] = objRect.right;

								if ( objRect.bottom < 0 || objRect.right < 0 ||
									objRect.top > results.clientHeight || objRect.left > results.clientWidth ) {
									//Entire object is out of viewport
									results[ 'percentViewable' ] = 0;
								} else {
									xMin = Math.ceil( Math.max( 0, objRect.left ) );
									xMax = Math.floor( Math.min( results.clientWidth, objRect.right ) );
									yMin = Math.ceil( Math.max( 0, objRect.top ) );
									yMax = Math.floor( Math.min( results.clientHeight, objRect.bottom ) );
									var visibleObjectArea = ( xMax - xMin + 1 ) * ( yMax - yMin + 1 );
									results[ 'percentViewable' ] = Math.round( visibleObjectArea / totalObjectArea * 100 );
								}
								//Report window focus (Is the window active?):
								var chromeNotVisible = 	!!document.webkitVisibilityState &&
														document.webkitVisibilityState != 'visible';
								results[ 'focus' ] = window.document.hasFocus() && !chromeNotVisible;
							}
					}

					if ( results["errCode"] == 'e0' &&  window.self !== window.top ) { //Check for iFrames
							results["error"] =  "Ad in iFrame";
							results["errCode"] = "eIF";
							
							//can find viewability in iFRame if Firefox
							if (results[ 'percentViewable' ] > 0 && window.self.mozInnerScreenX !== undefined) {
								results[ 'mozViewable' ] = results[ 'percentViewable' ];
								var w = window.self;
								while( w.self != w.top ) {
									var dX = w.mozInnerScreenX - w.parent.mozInnerScreenX;
									var dY = w.mozInnerScreenY - w.parent.mozInnerScreenY;
									w = w.parent;

									xMin +=dX; xMin = Math.ceil( Math.max( 0, xMin ) );
									xMax +=dX; xMax = Math.floor( Math.min( w.innerWidth, xMax ) );
									yMin +=dY; yMin = Math.ceil( Math.max( 0, yMin ) );
									yMax +=dY; yMax = Math.floor( Math.min( w.innerHeight, yMax ) );
									if (xMin>=xMax || yMin>=yMax) {
										results[ 'mozViewable' ] = 0; break;
									}
								}
								if (results[ 'mozViewable' ] > 0) {
									 results[ 'mozViewable' ] = Math.round( ( xMax - xMin  ) * ( yMax - yMin  ) / totalObjectArea * 100 );
								}
 							}
					}


						
				
					if (myObj) {	//Check if overlaps with other elements
						var ii = 0;	
						for(var ix = 0.25; ix < 1; ix +=0.3) {
							for(var iy = 0.25; iy < 1; iy +=0.3) {
								ii+=(document.elementFromPoint(objRect.left + (objRect.right - objRect.left) * ix,
								objRect.top + (objRect.bottom-objRect.top) * iy) == myObj) ? 1 : 0;
							}
						}
						results['ovlViewable'] = Math.round( ii* 100/9 );

					}

					return results;
				}
			]]></script>;
		return ExternalInterface.call(js, uniqueId ) as Object;
	}
}
}
