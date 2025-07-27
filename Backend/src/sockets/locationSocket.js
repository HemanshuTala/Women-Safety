module.exports = (io) => {
  const emitLocation = (userId, locationData) => {
    io.emit('location_update', { userId, ...locationData });
  };
  return { emitLocation };
};
