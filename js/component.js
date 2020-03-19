const getComponentsEnv = (componentsRoot, getMemory, customEventCallback) => {
  const TAG_DIV = 1;
  const TAG_P = 2;
  const TAG_BUTTON = 3;

  let elements = [];

  return {
    element_render_begin: () => {
      // Clear all elements from root component
      while (componentsRoot.firstChild) {
        componentsRoot.removeChild(componentsRoot.firstChild);
      }
      // Create an id for the zig code to reference
      const id = elements.length;
      elements.push(componentsRoot);
      return id;
    },
    element_render_end: () => (elements = []),

    element_create: tag => {
      let elementStr = "";
      switch (tag) {
        case TAG_DIV:
          elementStr = "div";
          break;
        case TAG_P:
          elementStr = "p";
          break;
        case TAG_BUTTON:
          elementStr = "button";
          break;
        default:
          console.log("Unknown tag number, rendering component as a div");
          elementStr = "div";
          break;
      }
      const element = document.createElement(elementStr);
      const id = elements.length;
      elements.push(element);
      return id;
    },

    element_setTextS: (elemId, textPtr, textLen) => {
      const element = elements[elemId];
      const bytes = new Uint8Array(getMemory().buffer, textPtr, textLen);
      let s = "";
      for (const b of bytes) {
        s += String.fromCharCode(b);
      }
      element.textContent = s;
    },

    element_setClickEvent: (elemId, clickEvent) => {
      elements[elemId].addEventListener("click", () => {
        customEventCallback(clickEvent);
      });
    },

    element_appendChild: (parentElemId, childElemId) => {
      const parentElem = elements[parentElemId];
      const childElem = elements[childElemId];
      parentElem.appendChild(childElem);
    }
  };
};

export default getComponentsEnv;
