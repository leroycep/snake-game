const getComponentsEnv = (componentsRoot, getMemory, customEventCallback) => {
  const TAG_DIV = 1;
  const TAG_P = 2;
  const TAG_BUTTON = 3;

  const CLASS_HORIZONTAL = 1;
  const CLASS_VERTICAL = 2;

  let elements = [];
  let unused_ids = [];
  let clickEvents = {};
  let hoverEvents = {};

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
      element.classList.add("component");
      const id = unused_ids.length > 0 ? unused_ids.pop() : elements.length;
      elements[id] = element;
      return id;
    },

    element_remove: elemId => {
      if (elemId < elements.length && !unused_ids.includes(elemId)) {
        elements[elemId].remove();
        elements[elemId] = null;
        unused_ids.push(elemId);
      }
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
      clickEvents[elemId] = () => customEventCallback(clickEvent);
      elements[elemId].addEventListener("click", clickEvents[elemId]);
    },

    element_removeClickEvent: (elemId, clickEvent) => {
      elements[elemId].removeEventListener("click", clickEvents[elemId]);
    },

    element_setHoverEvent: (elemId, hoverEvent) => {
      hoverEvents[elemId] = () => customEventCallback(hoverEvent);
      elements[elemId].addEventListener("mouseover", hoverEvents[elemId]);
    },

    element_removeHoverEvent: (elemId, clickEvent) => {
      elements[elemId].removeEventListener("click", hoverEvents[elemId]);
    },

    element_addClass: (elemId, classNumber) => {
      let classStr = "";
      switch (classNumber) {
        case CLASS_HORIZONTAL:
          classStr = "horizontal";
          break;
        case CLASS_VERTICAL:
          classStr = "vertical";
          break;
        default:
          console.log("Unknown class number", classNumber);
          return;
      }
      elements[elemId].classList.add(classStr);
    },

    element_setGrow: (elemId, grow) => {
      elements[elemId].style.flexGrow = grow;
    },

    element_appendChild: (parentElemId, childElemId) => {
      const parentElem = elements[parentElemId];
      const childElem = elements[childElemId];
      parentElem.appendChild(childElem);
    }
  };
};

export default getComponentsEnv;
